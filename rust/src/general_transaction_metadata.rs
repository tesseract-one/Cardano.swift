use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::metadata_list::MetadataList;
use crate::metadata_map::MetadataMap;
use crate::panic::*;
use crate::ptr::*;
use crate::string::*;
use crate::transaction_metadatum_labels::TransactionMetadatumLabel;
use cardano_serialization_lib::{
  metadata::{
    GeneralTransactionMetadata as RGeneralTransactionMetadata,
    TransactionMetadatum as RTransactionMetadatum, TransactionMetadatumKind,
  },
  utils::{from_bignum, to_bignum, Int},
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub enum TransactionMetadatum {
  MetadataMapKind(MetadataMap),
  MetadataListKind(MetadataList),
  IntKind(u64),
  BytesKind(CData),
  TextKind(CharPtr),
}

impl Free for TransactionMetadatum {
  unsafe fn free(&mut self) {
    match self {
      TransactionMetadatum::MetadataMapKind(metadata_map) => metadata_map.free(),
      TransactionMetadatum::MetadataListKind(metadata_list) => metadata_list.free(),
      TransactionMetadatum::BytesKind(bytes) => bytes.free(),
      TransactionMetadatum::TextKind(text) => text.free(),
      _ => return,
    }
  }
}

impl Clone for TransactionMetadatum {
  fn clone(&self) -> Self {
    match self {
      TransactionMetadatum::MetadataMapKind(metadata_map) => {
        Self::MetadataMapKind(metadata_map.clone())
      }
      TransactionMetadatum::MetadataListKind(metadata_list) => {
        Self::MetadataListKind(metadata_list.clone())
      }
      TransactionMetadatum::IntKind(int) => Self::IntKind(int.clone()),
      TransactionMetadatum::BytesKind(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self::BytesKind(bytes.into())
      }
      TransactionMetadatum::TextKind(text) => {
        let text = unsafe { text.unowned().expect("Bad char pointer") };
        Self::TextKind(text.into_cstr())
      }
    }
  }
}

impl TryFrom<TransactionMetadatum> for RTransactionMetadatum {
  type Error = CError;

  fn try_from(transaction_metadatum: TransactionMetadatum) -> Result<Self> {
    match transaction_metadatum {
      TransactionMetadatum::MetadataMapKind(metadata_map) => metadata_map
        .try_into()
        .map(|metadata_map| Self::new_map(&metadata_map)),
      TransactionMetadatum::MetadataListKind(metadata_list) => metadata_list
        .try_into()
        .map(|metadata_list| Self::new_list(&metadata_list)),
      TransactionMetadatum::IntKind(int) => Ok(Self::new_int(&Int::new(&to_bignum(int)))),
      TransactionMetadatum::BytesKind(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self::new_bytes(bytes.to_vec()).into_result()
      }
      TransactionMetadatum::TextKind(text) => {
        let text = unsafe { text.unowned().expect("Bad char pointer") };
        Self::new_text(text.to_string()).into_result()
      }
    }
  }
}

impl TryFrom<RTransactionMetadatum> for TransactionMetadatum {
  type Error = CError;

  fn try_from(transaction_metadatum: RTransactionMetadatum) -> Result<Self> {
    match transaction_metadatum.kind() {
      TransactionMetadatumKind::MetadataMap => transaction_metadatum
        .as_map()
        .into_result()
        .and_then(|metadata_map| metadata_map.try_into())
        .map(|metadata_map| Self::MetadataMapKind(metadata_map)),
      TransactionMetadatumKind::MetadataList => transaction_metadatum
        .as_list()
        .into_result()
        .and_then(|metadata_list| metadata_list.try_into())
        .map(|metadata_list| Self::MetadataListKind(metadata_list)),
      TransactionMetadatumKind::Int => transaction_metadatum.as_int().into_result().map(|int| {
        Self::IntKind(from_bignum(
          &int.as_positive().or(int.as_negative()).unwrap(),
        ))
      }),
      TransactionMetadatumKind::Bytes => transaction_metadatum
        .as_bytes()
        .into_result()
        .map(|bytes| Self::BytesKind(bytes.into())),
      TransactionMetadatumKind::Text => transaction_metadatum
        .as_text()
        .into_result()
        .map(|text| Self::TextKind(text.into_cstr())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_clone(
  transaction_metadatum: TransactionMetadatum, result: &mut TransactionMetadatum,
  error: &mut CError,
) -> bool {
  handle_exception(|| transaction_metadatum.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_free(
  transaction_metadatum: &mut TransactionMetadatum,
) {
  transaction_metadatum.free()
}

pub type GeneralTransactionMetadataKeyValue =
  CKeyValue<TransactionMetadatumLabel, TransactionMetadatum>;
pub type GeneralTransactionMetadata = CArray<GeneralTransactionMetadataKeyValue>;

impl TryFrom<GeneralTransactionMetadata> for RGeneralTransactionMetadata {
  type Error = CError;

  fn try_from(general_transaction_metadata: GeneralTransactionMetadata) -> Result<Self> {
    let map = unsafe { general_transaction_metadata.as_hash_map()? };
    let mut general_transaction_metadata = Self::new();
    for (tm_label, tm) in map {
      let transaction_metadatum = tm.try_into()?;
      general_transaction_metadata.insert(&to_bignum(tm_label), &transaction_metadatum);
    }
    Ok(general_transaction_metadata)
  }
}

impl TryFrom<RGeneralTransactionMetadata> for GeneralTransactionMetadata {
  type Error = CError;

  fn try_from(general_transaction_metadata: RGeneralTransactionMetadata) -> Result<Self> {
    Ok(general_transaction_metadata.keys()).and_then(|tm_labels| {
      (0..tm_labels.len())
        .map(|index| tm_labels.get(index))
        .map(|tm_label| {
          general_transaction_metadata
            .get(&tm_label)
            .ok_or("Cannot get TransactionMetadatum by TransactionMetadatumLabel".into())
            .and_then(|tm| tm.try_into())
            .map(|tm| (from_bignum(&tm_label), tm).into())
        })
        .collect::<Result<Vec<GeneralTransactionMetadataKeyValue>>>()
        .map(|general_transaction_metadata| general_transaction_metadata.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_general_transaction_metadata_free(
  general_transaction_metadata: &mut GeneralTransactionMetadata,
) {
  general_transaction_metadata.free()
}
