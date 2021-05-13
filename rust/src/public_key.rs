use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::Ptr;
use super::stake_credential::Ed25519KeyHash;
use super::string::CharPtr;
use super::string::IntoCString;
use cardano_serialization_lib::crypto::PublicKey as RPublicKey;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct PublicKey(CharPtr);

impl Clone for PublicKey {
  fn clone(&self) -> Self {
    let s: String = unsafe { self.0.unowned().expect("Bad char pointer").into() };
    Self(s.into_cstr())
  }
}

impl From<RPublicKey> for PublicKey {
  fn from(public_key: RPublicKey) -> Self {
    Self(public_key.to_bech32().into_cstr())
  }
}

impl TryFrom<PublicKey> for RPublicKey {
  type Error = CError;

  fn try_from(public_key: PublicKey) -> Result<Self> {
    let bech32_str = unsafe { public_key.0.unowned()? };
    RPublicKey::from_bech32(bech32_str).into_result()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_from_bech32(
  bech32_str: CharPtr, result: &mut PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bech32_str.unowned()
      .and_then(|bech32_str| RPublicKey::from_bech32(bech32_str).into_result())
      .map(|public_key| public_key.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_to_bech32(
  public_key: PublicKey, result: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    public_key
      .try_into()
      .map(|public_key: RPublicKey| public_key.to_bech32().into_cstr())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_from_bytes(
  data: CData, result: &mut PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RPublicKey::from_bytes(bytes).into_result())
      .map(|public_key| public_key.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_as_bytes(
  public_key: PublicKey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    public_key
      .try_into()
      .map(|public_key: RPublicKey| public_key.as_bytes().into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_hash(
  public_key: PublicKey, result: &mut Ed25519KeyHash, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    public_key
      .try_into()
      .and_then(|public_key: RPublicKey| public_key.hash().try_into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_clone(
  public_key: PublicKey, result: &mut PublicKey, error: &mut CError
) -> bool {
  handle_exception(|| public_key.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_public_key_free(public_key: &mut PublicKey) {
  public_key.0.free();
}
