use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::int::CInt128;
use crate::metadata_list::MetadataList;
use crate::metadata_map::MetadataMap;
use crate::panic::*;
use crate::ptr::*;
use crate::string::*;
use crate::transaction_metadatum_labels::TransactionMetadatumLabel;
use cardano_serialization_lib::{
  metadata::{
    decode_arbitrary_bytes_from_metadatum, decode_metadatum_to_json_str,
    encode_arbitrary_bytes_as_metadatum, encode_json_str_to_metadatum,
    GeneralTransactionMetadata as RGeneralTransactionMetadata,
    MetadataJsonSchema as RMetadataJsonSchema, TransactionMetadatum as RTransactionMetadatum,
    TransactionMetadatumKind,
  },
  utils::{from_bignum, to_bignum, Int as RInt},
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum MetadataJsonSchema {
  NoConversions,
  BasicConversions,
  DetailedSchema,
}

impl From<MetadataJsonSchema> for RMetadataJsonSchema {
  fn from(metadata_json_schema: MetadataJsonSchema) -> Self {
    match metadata_json_schema {
      MetadataJsonSchema::NoConversions => Self::NoConversions,
      MetadataJsonSchema::BasicConversions => Self::BasicConversions,
      MetadataJsonSchema::DetailedSchema => Self::DetailedSchema,
    }
  }
}

impl From<RMetadataJsonSchema> for MetadataJsonSchema {
  fn from(metadata_json_schema: RMetadataJsonSchema) -> Self {
    match metadata_json_schema {
      RMetadataJsonSchema::NoConversions => Self::NoConversions,
      RMetadataJsonSchema::BasicConversions => Self::BasicConversions,
      RMetadataJsonSchema::DetailedSchema => Self::DetailedSchema,
    }
  }
}

#[repr(C)]
#[derive(Copy)]
pub enum TransactionMetadatum {
  MetadataMapKind(MetadataMap),
  MetadataListKind(MetadataList),
  IntKind(CInt128),
  BytesKind(CData),
  TextKind(CharPtr),
}

// for transmute
pub struct TInt(i128);

impl From<CInt128> for RInt {
  fn from(int: CInt128) -> Self {
    unsafe { std::mem::transmute(TInt(int.into())) }
  }
}

impl From<RInt> for CInt128 {
  fn from(int: RInt) -> Self {
    let int: TInt = unsafe { std::mem::transmute(int) };
    int.0.into()
  }
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
      TransactionMetadatum::IntKind(int) => Ok(Self::new_int(&int.into())),
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
      TransactionMetadatumKind::Int => transaction_metadatum
        .as_int()
        .into_result()
        .map(|int| Self::IntKind(int.into())),
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
pub unsafe extern "C" fn cardano_transaction_metadatum_new_bytes(
  bytes: CData, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .and_then(|bytes| RTransactionMetadatum::new_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_new_text(
  text: CharPtr, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    text
      .unowned()
      .and_then(|text| RTransactionMetadatum::new_text(text.to_string()).into_result())
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_encode_arbitrary_bytes_as_metadatum(
  bytes: CData, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .map(|bytes| encode_arbitrary_bytes_as_metadatum(bytes))
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_decode_arbitrary_bytes_from_metadatum(
  transaction_metadatum: TransactionMetadatum, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_metadatum
      .try_into()
      .and_then(|transaction_metadatum| {
        decode_arbitrary_bytes_from_metadatum(&transaction_metadatum).into_result()
      })
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_encode_json_str_to_metadatum(
  json: CharPtr, schema: MetadataJsonSchema, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    json
      .unowned()
      .and_then(|json| encode_json_str_to_metadatum(json.to_string(), schema.into()).into_result())
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_decode_metadatum_to_json_str(
  transaction_metadatum: TransactionMetadatum, schema: MetadataJsonSchema, result: &mut CharPtr,
  error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_metadatum
      .try_into()
      .and_then(|transaction_metadatum| {
        decode_metadatum_to_json_str(&transaction_metadatum, schema.into()).into_result()
      })
      .map(|bytes| bytes.into_cstr())
  })
  .response(result, error)
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
