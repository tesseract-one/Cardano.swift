use crate::data::CData;
use crate::error::CError;
use crate::option::COption;
use crate::panic::*;
use crate::ptr::*;
use crate::transaction_body::TransactionBody;
use crate::transaction_metadata::TransactionMetadata;
use crate::transaction_witness_set::TransactionWitnessSet;
use cardano_serialization_lib::Transaction as RTransaction;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Transaction {
  body: TransactionBody,
  witness_set: TransactionWitnessSet,
  metadata: COption<TransactionMetadata>,
}

impl Free for Transaction {
  unsafe fn free(&mut self) {
    self.body.free();
    self.witness_set.free();
    self.metadata.free();
  }
}

impl TryFrom<Transaction> for RTransaction {
  type Error = CError;

  fn try_from(transaction: Transaction) -> Result<Self> {
    transaction
      .body
      .try_into()
      .zip(transaction.witness_set.try_into())
      .zip({
        let metadata: Option<TransactionMetadata> = transaction.metadata.into();
        metadata.map(|metadata| metadata.try_into()).transpose()
      })
      .map(|((body, witness_set), metadata)| Self::new(&body, &witness_set, metadata))
  }
}

impl TryFrom<RTransaction> for Transaction {
  type Error = CError;

  fn try_from(transaction: RTransaction) -> Result<Self> {
    transaction
      .body()
      .try_into()
      .zip(transaction.witness_set().try_into())
      .zip(transaction.metadata().map(|m| m.try_into()).transpose())
      .map(|((body, witness_set), metadata)| Self {
        body,
        witness_set,
        metadata: metadata.into(),
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_to_bytes(
  transaction: Transaction, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction
      .try_into()
      .map(|transaction: RTransaction| transaction.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_from_bytes(
  data: CData, result: &mut Transaction, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransaction::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction| transaction.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_clone(
  transaction: Transaction, result: &mut Transaction, error: &mut CError,
) -> bool {
  handle_exception(|| transaction.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_free(transaction: &mut Transaction) {
  transaction.free();
}
