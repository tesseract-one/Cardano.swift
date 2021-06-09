use super::transaction_hash::TransactionHash;
use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::Ptr;
use cardano_serialization_lib::TransactionInput as RTransactionInput;
use std::convert::{TryFrom, TryInto};

pub type TransactionIndex = u32;

#[repr(C)]
#[derive(Clone, Copy)]
pub struct TransactionInput {
  transaction_id: TransactionHash,
  index: TransactionIndex,
}

impl From<TransactionInput> for RTransactionInput {
  fn from(transaction_input: TransactionInput) -> Self {
    RTransactionInput::new(
      &transaction_input.transaction_id.into(),
      transaction_input.index,
    )
  }
}

impl TryFrom<RTransactionInput> for TransactionInput {
  type Error = CError;

  fn try_from(transaction_input: RTransactionInput) -> Result<Self> {
    transaction_input
      .transaction_id()
      .try_into()
      .map(|transaction_id| TransactionInput {
        transaction_id,
        index: transaction_input.index(),
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_input_to_bytes(
  transaction_input: TransactionInput, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception(|| {
    let transaction_input: RTransactionInput = transaction_input.into();
    transaction_input.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_input_from_bytes(
  data: CData, result: &mut TransactionInput, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionInput::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_input| transaction_input.try_into())
  })
  .response(result, error)
}
