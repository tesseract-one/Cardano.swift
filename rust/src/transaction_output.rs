use crate::address::address::Address;
use crate::array::CArray;
use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use crate::value::Value;
use cardano_serialization_lib::{
  TransactionOutput as RTransactionOutput, TransactionOutputs as RTransactionOutputs,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionOutput {
  address: Address,
  amount: Value,
}

impl Free for TransactionOutput {
  unsafe fn free(&mut self) {
    self.address.free();
    self.amount.free();
  }
}

impl TryFrom<TransactionOutput> for RTransactionOutput {
  type Error = CError;

  fn try_from(transaction_output: TransactionOutput) -> Result<Self> {
    transaction_output
      .address
      .try_into()
      .zip(transaction_output.amount.try_into())
      .map(|(address, amount)| Self::new(&address, &amount))
  }
}

impl TryFrom<RTransactionOutput> for TransactionOutput {
  type Error = CError;

  fn try_from(transaction_output: RTransactionOutput) -> Result<Self> {
    transaction_output
      .address()
      .try_into()
      .zip(transaction_output.amount().try_into())
      .map(|(address, amount)| Self { address, amount })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_output_to_bytes(
  transaction_output: TransactionOutput, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_output
      .try_into()
      .map(|transaction_output: RTransactionOutput| transaction_output.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_output_from_bytes(
  data: CData, result: &mut TransactionOutput, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionOutput::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_output| transaction_output.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_output_clone(
  transaction_output: TransactionOutput, result: &mut TransactionOutput, error: &mut CError,
) -> bool {
  handle_exception(|| transaction_output.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_output_free(
  transaction_output: &mut TransactionOutput,
) {
  transaction_output.free();
}

pub type TransactionOutputs = CArray<TransactionOutput>;

impl TryFrom<TransactionOutputs> for RTransactionOutputs {
  type Error = CError;

  fn try_from(transaction_outputs: TransactionOutputs) -> Result<Self> {
    let vec = unsafe { transaction_outputs.unowned()? };
    let mut transaction_outputs = Self::new();
    for transaction_output in vec.to_vec() {
      let transaction_output = transaction_output.try_into()?;
      transaction_outputs.add(&transaction_output);
    }
    Ok(transaction_outputs)
  }
}

impl TryFrom<RTransactionOutputs> for TransactionOutputs {
  type Error = CError;

  fn try_from(transaction_outputs: RTransactionOutputs) -> Result<Self> {
    (0..transaction_outputs.len())
      .map(|index| transaction_outputs.get(index))
      .map(|transaction_output| transaction_output.try_into())
      .collect::<Result<Vec<TransactionOutput>>>()
      .map(|transaction_outputs| transaction_outputs.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_outputs_free(
  transaction_outputs: &mut TransactionOutputs,
) {
  transaction_outputs.free();
}
