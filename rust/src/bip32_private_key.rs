use std::convert::{TryInto, TryFrom};
use crate::private_key::PrivateKey;
use super::data::CData;
use super::ptr::Ptr;
use super::error::CError;
use super::panic::*;
use super::string::*;
use super::bip32_public_key::Bip32PublicKey;
use cardano_serialization_lib::crypto::{Bip32PrivateKey as RBip32PrivateKey};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Bip32PrivateKey([u8; 96]);

impl TryFrom<Bip32PrivateKey> for RBip32PrivateKey {
  type Error = CError;

  fn try_from(pk: Bip32PrivateKey) -> Result<Self> {
    Self::from_bytes(&pk.0).map_err(|e| e.into())
  }
}

impl From<RBip32PrivateKey> for Bip32PrivateKey {
  fn from(pk: RBip32PrivateKey) -> Self {
    Self(pk.as_bytes().try_into().unwrap())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_derive(
  pk: Bip32PrivateKey, index: u32, result: &mut Bip32PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PrivateKey| pk.derive(index))
      .map(|pk| pk.into())
      .into_result()
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_generate_ed25519_bip32(
  result: &mut Bip32PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    RBip32PrivateKey::generate_ed25519_bip32()
      .map(|pk| pk.into())
      .into_result()
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_to_raw_key(
  pk: Bip32PrivateKey, result: &mut PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PrivateKey| pk.to_raw_key())
      .map(|pk| pk.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_to_public(
  pk: Bip32PrivateKey, result: &mut Bip32PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into().map(|pk: RBip32PrivateKey| pk.to_public().into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_from_bytes(
  data: CData, result: &mut Bip32PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RBip32PrivateKey::from_bytes(bytes).into_result())
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_as_bytes(
  pk: Bip32PrivateKey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PrivateKey| pk.as_bytes())
      .map(|bytes| bytes.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_from_bech32(
  bech32_str: CharPtr, result: &mut Bip32PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bech32_str.unowned()
      .and_then(|b32| RBip32PrivateKey::from_bech32(b32).into_result())
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_to_bech32(
  pk: Bip32PrivateKey, result: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    pk.try_into().map(|pk: RBip32PrivateKey| pk.to_bech32().into_cstr())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_from_bip39_entropy(
  entropy: CData, password: CData,
  result: &mut Bip32PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    entropy.unowned().zip(password.unowned())
      .map(|(ent, pwd)| RBip32PrivateKey::from_bip39_entropy(ent, pwd))
      .map(|pk| pk.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_from_128_xprv(
  data: CData, result: &mut Bip32PrivateKey, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RBip32PrivateKey::from_128_xprv(bytes).into_result())
      .map(|pk| pk.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_to_128_xprv(
  pk: Bip32PrivateKey, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PrivateKey| pk.to_128_xprv())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bip32_private_key_chaincode(
  pk: Bip32PrivateKey, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    pk.try_into()
      .map(|pk: RBip32PrivateKey| pk.chaincode())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}
