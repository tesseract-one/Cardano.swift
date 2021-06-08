use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::Ptr;
use cardano_serialization_lib::crypto::TransactionHash as RTransactionHash;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Clone, Copy)]
pub struct TransactionHash(pub [u8; 32]);

impl TryFrom<RTransactionHash> for TransactionHash {
  type Error = CError;

  fn try_from(transaction_hash: RTransactionHash) -> Result<Self> {
    let bytes: [u8; 32] = transaction_hash
      .to_bytes()
      .try_into()
      .map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self(bytes))
  }
}

impl From<TransactionHash> for RTransactionHash {
  fn from(transaction_hash: TransactionHash) -> Self {
    transaction_hash.0.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_hash_to_bytes(
  transaction_hash: TransactionHash, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception(|| {
    let transaction_hash: RTransactionHash = transaction_hash.into();
    transaction_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_hash_from_bytes(
  data: CData, result: &mut TransactionHash, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionHash::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_hash| transaction_hash.try_into())
  })
  .response(result, error)
}
