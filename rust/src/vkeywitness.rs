use crate::array::CArray;
use crate::ed25519_signature::Ed25519Signature;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use crate::vkey::Vkey;
use cardano_serialization_lib::crypto::{
  Vkeywitness as RVkeywitness, Vkeywitnesses as RVkeywitnesses,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Vkeywitness {
  vkey: Vkey,
  signature: Ed25519Signature,
}

impl Free for Vkeywitness {
  unsafe fn free(&mut self) {
    self.vkey.free();
    self.signature.free();
  }
}

impl TryFrom<Vkeywitness> for RVkeywitness {
  type Error = CError;

  fn try_from(vkeywitness: Vkeywitness) -> Result<Self> {
    vkeywitness
      .vkey
      .try_into()
      .zip(vkeywitness.signature.try_into())
      .map(|(vkey, signature)| RVkeywitness::new(&vkey, &signature))
  }
}

impl From<RVkeywitness> for Vkeywitness {
  fn from(vkeywitness: RVkeywitness) -> Self {
    Self {
      vkey: vkeywitness.vkey().into(),
      signature: vkeywitness.signature().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkeywitness_clone(
  vkeywitness: Vkeywitness, result: &mut Vkeywitness, error: &mut CError,
) -> bool {
  handle_exception(|| vkeywitness.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkeywitness_free(vkeywitness: &mut Vkeywitness) {
  vkeywitness.free()
}

pub type Vkeywitnesses = CArray<Vkeywitness>;

impl From<RVkeywitnesses> for Vkeywitnesses {
  fn from(vkeywitnesses: RVkeywitnesses) -> Self {
    (0..vkeywitnesses.len())
      .map(|index| vkeywitnesses.get(index))
      .map(|vkeywitness| vkeywitness.into())
      .collect::<Vec<Vkeywitness>>()
      .into()
  }
}

impl TryFrom<Vkeywitnesses> for RVkeywitnesses {
  type Error = CError;

  fn try_from(vkeywitnesses: Vkeywitnesses) -> Result<Self> {
    let vec = unsafe { vkeywitnesses.unowned()? };
    let mut vkeywitnesses = RVkeywitnesses::new();
    for vkeywitness in vec.to_vec() {
      let vkeywitness = vkeywitness.try_into()?;
      vkeywitnesses.add(&vkeywitness);
    }
    Ok(vkeywitnesses)
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vkeywitnesses_free(vkeywitnesses: &mut Vkeywitnesses) {
  vkeywitnesses.free();
}
