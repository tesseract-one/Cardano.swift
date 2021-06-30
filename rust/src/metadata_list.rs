use crate::array::*;
use crate::error::CError;
use crate::general_transaction_metadata::TransactionMetadatum;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::metadata::MetadataList as RMetadataList;
use std::convert::{TryFrom, TryInto};

pub type MetadataList = CArray<TransactionMetadatum>;

impl TryFrom<MetadataList> for RMetadataList {
  type Error = CError;

  fn try_from(metadata_list: MetadataList) -> Result<Self> {
    let vec = unsafe { metadata_list.unowned()? };
    let mut metadata_list = RMetadataList::new();
    for transaction_metadatum in vec.to_vec() {
      let transaction_metadatum = transaction_metadatum.try_into()?;
      metadata_list.add(&transaction_metadatum);
    }
    Ok(metadata_list)
  }
}

impl TryFrom<RMetadataList> for MetadataList {
  type Error = CError;

  fn try_from(metadata_list: RMetadataList) -> Result<Self> {
    (0..metadata_list.len())
      .map(|index| metadata_list.get(index))
      .map(|transaction_metadatum| transaction_metadatum.try_into())
      .collect::<Result<Vec<TransactionMetadatum>>>()
      .map(|metadata_list| metadata_list.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_metadata_list_free(metadata_list: &mut MetadataList) {
  metadata_list.free();
}
