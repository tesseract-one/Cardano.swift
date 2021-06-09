use crate::array::CArray;
use crate::ptr::Free;
use crate::transaction_input::TransactionInput;

pub type TransactionInputs = CArray<TransactionInput>;

impl Free for TransactionInput {
  unsafe fn free(&mut self) {}
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_inputs_free(
  transaction_inputs: &mut TransactionInputs
) {
  transaction_inputs.free();
}
