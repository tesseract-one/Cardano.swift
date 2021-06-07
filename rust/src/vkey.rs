use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::*;
use super::public_key::PublicKey;
use cardano_serialization_lib::crypto::Vkey as RVkey;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct Vkey(pub PublicKey);

impl Clone for Vkey {
  fn clone(&self) -> Self {
    Self(self.0.clone())
  }
}

impl Free for Vkey {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl Ptr for Vkey {
  type PT = str;

  unsafe fn unowned(&self) -> Result<&Self::PT> {
    self.0.unowned()
  }
}

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

#[no_mangle]
pub unsafe extern "C" fn cardano_vkey_clone(
  vkey: Vkey, result: &mut Vkey, error: &mut CError
) -> bool {
  handle_exception(|| vkey.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkey_free(vkey: &mut Vkey) {
  vkey.free();
}
