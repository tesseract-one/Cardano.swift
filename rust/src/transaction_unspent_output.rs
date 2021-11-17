use std::convert::{TryFrom, TryInto};

use cardano_serialization_lib::utils::{
  TransactionUnspentOutput as RTransactionUnspentOutput,
  TransactionUnspentOutputs as RTransactionUnspentOutputs,
};

use crate::{
  array::CArray,
  error::CError,
  panic::*,
  ptr::{Free, Ptr},
  transaction_input::TransactionInput,
  transaction_output::TransactionOutput,
};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionUnspentOutput {
  input: TransactionInput,
  output: TransactionOutput,
}

impl Free for TransactionUnspentOutput {
  unsafe fn free(&mut self) {
    self.output.free()
  }
}

impl TryFrom<TransactionUnspentOutput> for RTransactionUnspentOutput {
  type Error = CError;

  fn try_from(transaction_unspent_output: TransactionUnspentOutput) -> Result<Self> {
    transaction_unspent_output
      .output
      .try_into()
      .map(|output| Self::new(&transaction_unspent_output.input.into(), &output))
  }
}

impl TryFrom<RTransactionUnspentOutput> for TransactionUnspentOutput {
  type Error = CError;

  fn try_from(transaction_unspent_output: RTransactionUnspentOutput) -> Result<Self> {
    transaction_unspent_output
      .input()
      .try_into()
      .zip(transaction_unspent_output.output().try_into())
      .map(|(input, output)| Self { input, output })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_unspent_output_clone(
  transaction_unspent_output: TransactionUnspentOutput, result: &mut TransactionUnspentOutput,
  error: &mut CError,
) -> bool {
  handle_exception(|| transaction_unspent_output.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_unspent_output_free(
  transaction_unspent_output: &mut TransactionUnspentOutput,
) {
  transaction_unspent_output.free();
}

pub type TransactionUnspentOutputs = CArray<TransactionUnspentOutput>;

impl TryFrom<TransactionUnspentOutputs> for RTransactionUnspentOutputs {
  type Error = CError;

  fn try_from(transaction_unspent_outputs: TransactionUnspentOutputs) -> Result<Self> {
    let vec = unsafe { transaction_unspent_outputs.unowned()? };
    let mut transaction_unspent_outputs = Self::new();
    for transaction_unspent_output in vec.to_vec() {
      let transaction_unspent_output = transaction_unspent_output.try_into()?;
      transaction_unspent_outputs.add(&transaction_unspent_output);
    }
    Ok(transaction_unspent_outputs)
  }
}

impl TryFrom<RTransactionUnspentOutputs> for TransactionUnspentOutputs {
  type Error = CError;

  fn try_from(transaction_unspent_outputs: RTransactionUnspentOutputs) -> Result<Self> {
    (0..transaction_unspent_outputs.len())
      .map(|index| transaction_unspent_outputs.get(index))
      .map(|transaction_unspent_output| transaction_unspent_output.try_into())
      .collect::<Result<Vec<TransactionUnspentOutput>>>()
      .map(|transaction_unspent_outputs| transaction_unspent_outputs.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_unspent_outputs_free(
  transaction_unspent_outputs: &mut TransactionUnspentOutputs,
) {
  transaction_unspent_outputs.free();
}
