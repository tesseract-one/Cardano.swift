use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::Ptr;
use super::string::CharPtr;
use super::string::IntoCString;
use cardano_serialization_lib::crypto::Ed25519Signature as REd25519Signature;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Ed25519Signature(pub CData);

impl TryFrom<Ed25519Signature> for REd25519Signature {
  type Error = CError;

  fn try_from(ed25519_signature: Ed25519Signature) -> Result<Self> {
    unsafe {
      ed25519_signature.0.unowned()
        .and_then(|bytes| REd25519Signature::from_bytes(bytes.to_vec()).into_result())
    }
  }
}

impl From<REd25519Signature> for Ed25519Signature {
  fn from(ed25519_signature: REd25519Signature) -> Self {
    Ed25519Signature(ed25519_signature.to_bytes().into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_ed25519_signature_to_bytes(
  ed25519_signature: Ed25519Signature, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    ed25519_signature
      .try_into()
      .map(|ed25519_signature: REd25519Signature| ed25519_signature.to_bytes().into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_ed25519_signature_from_bytes(
  data: CData, result: &mut Ed25519Signature, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| REd25519Signature::from_bytes(bytes.to_vec()).into_result())
      .map(|ed25519_signature| ed25519_signature.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_ed25519_signature_to_hex(
  ed25519_signature: Ed25519Signature, result: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    ed25519_signature
      .try_into()
      .map(|ed25519_signature: REd25519Signature| ed25519_signature.to_hex().into_cstr())
  }).response(result, error)
}
