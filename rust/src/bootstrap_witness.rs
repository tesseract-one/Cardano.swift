use crate::data::CData;
use crate::ed25519_signature::Ed25519Signature;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use crate::vkey::Vkey;
use cardano_serialization_lib::crypto::BootstrapWitness as RBootstrapWitness;
use std::convert::TryFrom;
use std::convert::TryInto;

#[repr(C)]
#[derive(Copy)]
pub struct BootstrapWitness {
  vkey: Vkey,
  signature: Ed25519Signature,
  chain_code: CData,
  attributes: CData
}

impl Clone for BootstrapWitness {
  fn clone(&self) -> Self {
    let chain_code = unsafe { self.chain_code.unowned().expect("Bad bytes pointer").into() };
    let attributes = unsafe { self.attributes.unowned().expect("Bad bytes pointer").into() };
    BootstrapWitness {
      vkey: self.vkey.clone(),
      signature: self.signature.clone(),
      chain_code,
      attributes,
    }
  }
}

impl Free for BootstrapWitness {
  unsafe fn free(&mut self) {
    self.vkey.free();
    self.signature.free();
    self.chain_code.free();
    self.attributes.free();
  }
}

impl TryFrom<BootstrapWitness> for RBootstrapWitness {
  type Error = CError;

  fn try_from(bootstrap_witness: BootstrapWitness) -> Result<Self> {
    let chain_code = unsafe { bootstrap_witness.chain_code.unowned()? };
    let attributes = unsafe { bootstrap_witness.attributes.unowned()? };
    bootstrap_witness
      .vkey
      .try_into()
      .zip(bootstrap_witness.signature.try_into())
      .map(|(vkey, signature)| {
        RBootstrapWitness::new(&vkey, &signature, chain_code.to_vec(), attributes.to_vec())
      })
  }
}

impl From<RBootstrapWitness> for BootstrapWitness {
  fn from(bootstrap_witness: RBootstrapWitness) -> Self {
    Self {
      vkey: bootstrap_witness.vkey().into(),
      signature: bootstrap_witness.signature().into(),
      chain_code: bootstrap_witness.chain_code().into(),
      attributes: bootstrap_witness.attributes().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bootstrap_witness_clone(
  bootstrap_witness: BootstrapWitness, result: &mut BootstrapWitness, error: &mut CError
) -> bool {
  handle_exception(|| bootstrap_witness.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_bootstrap_witness_free(bootstrap_witness: &mut BootstrapWitness) {
  bootstrap_witness.free()
}
