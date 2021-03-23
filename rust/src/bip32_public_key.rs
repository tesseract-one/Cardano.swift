use std::convert::{TryInto, TryFrom};
use super::data::CData;
use super::ptr::Ptr;
use super::error::CError;
use super::panic::*;
use super::string::*;
use cardano_serialization_lib::crypto::{Bip32PublicKey as RBip32PublicKey};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Bip32PublicKey([u8; 64]);

impl TryFrom<Bip32PublicKey> for RBip32PublicKey {
  type Error = CError;

  fn try_from(pk: Bip32PublicKey) -> Result<Self> {
    Self::from_bytes(&pk.0).map_err(|e| e.into())
  }
}

impl From<RBip32PublicKey> for Bip32PublicKey {
  fn from(pk: RBip32PublicKey) -> Self {
    Self(pk.as_bytes().try_into().unwrap())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_derive(
  pk: Bip32PublicKey, index: u32, result: &mut Bip32PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .and_then(|pk: RBip32PublicKey| pk.derive(index).into_result())
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_from_bytes(
  data: CData, result: &mut Bip32PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RBip32PublicKey::from_bytes(bytes).into_result())
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_as_bytes(
  pk: Bip32PublicKey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PublicKey| pk.as_bytes())
      .map(|bytes| bytes.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_from_bech32(
  bech32_str: CharPtr, result: &mut Bip32PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bech32_str.unowned()
      .and_then(|b32| RBip32PublicKey::from_bech32(b32).into_result())
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_to_bech32(
  pk: Bip32PublicKey, result: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into().map(|pk: RBip32PublicKey| pk.to_bech32().into_cstr())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_public_key_chaincode(
  pk: Bip32PublicKey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PublicKey| pk.chaincode())
      .map(|bytes| bytes.into())
  }).response(result, error)
}