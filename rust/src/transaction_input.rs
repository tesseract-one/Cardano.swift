use super::transaction_hash::TransactionHash;
use crate::array::CArray;
use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::{
  TransactionInput as RTransactionInput, TransactionInputs as RTransactionInputs,
};
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
  transaction_input: TransactionInput, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let transaction_input: RTransactionInput = transaction_input.into();
    transaction_input.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_input_from_bytes(
  data: CData, result: &mut TransactionInput, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionInput::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_input| transaction_input.try_into())
  })
  .response(result, error)
}

pub type TransactionInputs = CArray<TransactionInput>;

impl Free for TransactionInput {
  unsafe fn free(&mut self) {}
}

impl TryFrom<TransactionInputs> for RTransactionInputs {
  type Error = CError;

  fn try_from(transaction_inputs: TransactionInputs) -> Result<Self> {
    let vec = unsafe { transaction_inputs.unowned()? };
    let mut transaction_inputs = Self::new();
    for transaction_input in vec.to_vec() {
      transaction_inputs.add(&transaction_input.into());
    }
    Ok(transaction_inputs)
  }
}

impl TryFrom<RTransactionInputs> for TransactionInputs {
  type Error = CError;

  fn try_from(transaction_inputs: RTransactionInputs) -> Result<Self> {
    (0..transaction_inputs.len())
      .map(|index| transaction_inputs.get(index))
      .map(|transaction_input| transaction_input.try_into())
      .collect::<Result<Vec<TransactionInput>>>()
      .map(|transaction_inputs| transaction_inputs.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_inputs_free(
  transaction_inputs: &mut TransactionInputs,
) {
  transaction_inputs.free();
}
