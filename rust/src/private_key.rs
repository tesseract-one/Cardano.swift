use super::data::CData;
use super::ed25519_signature::Ed25519Signature;
use super::error::CError;
use super::panic::*;
use super::ptr::*;
use super::public_key::PublicKey;
use cardano_serialization_lib::{
  crypto::PrivateKey as RPrivateKey,
  impl_mockchain::key::EitherEd25519SecretKey as REitherEd25519SecretKey,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct PrivateKey(pub EitherEd25519SecretKey);

impl Free for PrivateKey {
    unsafe fn free(&mut self) {
      match self.0 {
        EitherEd25519SecretKey::Extended(mut bytes) => bytes.free(),
        EitherEd25519SecretKey::Normal(mut bytes) => bytes.free()
      }
    }
}

impl Clone for PrivateKey {
  fn clone(&self) -> Self {
    match self.0 {
      EitherEd25519SecretKey::Extended(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self(EitherEd25519SecretKey::Extended(bytes.into()))
      },
      EitherEd25519SecretKey::Normal(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self(EitherEd25519SecretKey::Normal(bytes.into()))
      },
    }
  }
}

impl TryFrom<PrivateKey> for RPrivateKey {
  type Error = CError;

  fn try_from(private_key: PrivateKey) -> Result<Self> {
    match private_key.0 {
      EitherEd25519SecretKey::Extended(bytes) => {
        let bytes = unsafe { bytes.unowned()? };
        RPrivateKey::from_extended_bytes(bytes).into_result()
      },
      EitherEd25519SecretKey::Normal(bytes) => {
        let bytes = unsafe { bytes.unowned()? };
        RPrivateKey::from_normal_bytes(bytes).into_result()
      }
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum EitherEd25519SecretKey {
  Extended(CData),
  Normal(CData)
}

// For transmutation
struct TPrivateKey(REitherEd25519SecretKey);

impl From<RPrivateKey> for PrivateKey {
  fn from(private_key: RPrivateKey) -> Self {
    let bytes = private_key.as_bytes().into();
    let tpkey: TPrivateKey = unsafe { std::mem::transmute(private_key) };
    match tpkey.0 {
      REitherEd25519SecretKey::Extended(_) => Self(EitherEd25519SecretKey::Extended(bytes)),
      REitherEd25519SecretKey::Normal(_) => Self(EitherEd25519SecretKey::Normal(bytes)),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_to_public(
  private_key: PrivateKey, result: &mut PublicKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    private_key
      .try_into()
      .map(|private_key: RPrivateKey| private_key.to_public().into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_as_bytes(
  private_key: PrivateKey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    private_key
      .try_into()
      .map(|private_key: RPrivateKey| private_key.as_bytes().into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_from_extended_bytes(
  data: CData, result: &mut PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RPrivateKey::from_extended_bytes(bytes).into_result())
      .map(|private_key| private_key.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_from_normal_bytes(
  data: CData, result: &mut PrivateKey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RPrivateKey::from_normal_bytes(bytes).into_result())
      .map(|private_key| private_key.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_sign(
  private_key: PrivateKey, message: CData, result: &mut Ed25519Signature, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    private_key
      .try_into()
      .zip(message.unowned())
      .map(|(private_key, message): (RPrivateKey, &[u8])| private_key.sign(message))
      .map(|ed25519_signature| ed25519_signature.into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_clone(
  private_key: PrivateKey, result: &mut PrivateKey, error: &mut CError
) -> bool {
  handle_exception(|| private_key.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_private_key_free(private_key: &mut PrivateKey) {
  private_key.free()
}
