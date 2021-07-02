use crate::array::CArray;
use crate::error::CError;
use crate::panic::Result;
use crate::ptr::*;
use cardano_serialization_lib::{
  metadata::TransactionMetadatumLabels as RTransactionMetadatumLabels,
  utils::{from_bignum, to_bignum},
};
use std::convert::TryFrom;

pub type TransactionMetadatumLabel = u64;
pub type TransactionMetadatumLabels = CArray<TransactionMetadatumLabel>;

impl TryFrom<TransactionMetadatumLabels> for RTransactionMetadatumLabels {
  type Error = CError;

  fn try_from(transaction_metadatum_labels: TransactionMetadatumLabels) -> Result<Self> {
    let vec = unsafe { transaction_metadatum_labels.unowned()? };
    let mut transaction_metadatum_labels = Self::new();
    for transaction_metadatum_label in vec.to_vec() {
      transaction_metadatum_labels.add(&to_bignum(transaction_metadatum_label));
    }
    Ok(transaction_metadatum_labels)
  }
}

impl From<RTransactionMetadatumLabels> for TransactionMetadatumLabels {
  fn from(transaction_metadatum_labels: RTransactionMetadatumLabels) -> Self {
    (0..transaction_metadatum_labels.len())
      .map(|index| transaction_metadatum_labels.get(index))
      .map(|transaction_metadatum_label| from_bignum(&transaction_metadatum_label))
      .collect::<Vec<TransactionMetadatumLabel>>()
      .into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_labels_free(
  transaction_metadatum_labels: &mut TransactionMetadatumLabels,
) {
  transaction_metadatum_labels.free()
}
