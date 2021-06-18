use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::*;
use super::public_key::PublicKey;
use cardano_serialization_lib::crypto::Vkey as RVkey;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Vkey(pub PublicKey);

impl From<RVkey> for Vkey {
  fn from(vkey: RVkey) -> Self {
    Self(vkey.public_key().into())
  }
}

impl TryFrom<Vkey> for RVkey {
  type Error = CError;

  fn try_from(vkey: Vkey) -> Result<Self> {
    vkey.0.try_into().map(|pk| Self::new(&pk))
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkey_to_bytes(
  vkey: Vkey, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| vkey.try_into().map(|vkey: RVkey| vkey.to_bytes().into()))
    .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkey_from_bytes(
  data: CData, result: &mut Vkey, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RVkey::from_bytes(bytes.to_vec()).into_result())
      .map(|vkey| vkey.into())
  })
  .response(result, error)
}
