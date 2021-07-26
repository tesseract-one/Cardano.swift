use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::Ptr;
use cardano_serialization_lib::{
  crypto::{
    GenesisDelegateHash as RGenesisDelegateHash, GenesisHash as RGenesisHash,
    VRFKeyHash as RVRFKeyHash,
  },
  GenesisKeyDelegation as RGenesisKeyDelegation,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone, Hash, PartialEq, Eq)]
pub struct GenesisHash {
  bytes: [u8; 28],
  len: u8,
}

impl TryFrom<RGenesisHash> for GenesisHash {
  type Error = CError;

  fn try_from(hash: RGenesisHash) -> Result<Self> {
    let bytes = hash.to_bytes();
    let len = bytes.len() as u8;
    let bytes: [u8; 28] = bytes.try_into().map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self { bytes, len })
  }
}

impl From<GenesisHash> for RGenesisHash {
  fn from(hash: GenesisHash) -> Self {
    hash.bytes.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_genesis_hash_to_bytes(
  genesis_hash: GenesisHash, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let genesis_hash: RGenesisHash = genesis_hash.into();
    genesis_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_genesis_hash_from_bytes(
  data: CData, result: &mut GenesisHash, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RGenesisHash::from_bytes(bytes.to_vec()).into_result())
      .and_then(|genesis_hash| genesis_hash.try_into())
  })
  .response(result, error)
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct GenesisDelegateHash([u8; 28]);

impl From<RGenesisDelegateHash> for GenesisDelegateHash {
  fn from(hash: RGenesisDelegateHash) -> Self {
    Self(hash.to_bytes().try_into().unwrap())
  }
}

impl From<GenesisDelegateHash> for RGenesisDelegateHash {
  fn from(hash: GenesisDelegateHash) -> Self {
    hash.0.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_genesis_delegate_hash_to_bytes(
  genesis_delegate_hash: GenesisDelegateHash, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let genesis_delegate_hash: RGenesisDelegateHash = genesis_delegate_hash.into();
    genesis_delegate_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_genesis_delegate_hash_from_bytes(
  data: CData, result: &mut GenesisDelegateHash, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RGenesisDelegateHash::from_bytes(bytes.to_vec()).into_result())
      .map(|genesis_delegate_hash| genesis_delegate_hash.into())
  })
  .response(result, error)
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct VRFKeyHash([u8; 32]);

impl From<RVRFKeyHash> for VRFKeyHash {
  fn from(hash: RVRFKeyHash) -> Self {
    Self(hash.to_bytes().try_into().unwrap())
  }
}

impl From<VRFKeyHash> for RVRFKeyHash {
  fn from(hash: VRFKeyHash) -> Self {
    hash.0.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vrf_key_hash_to_bytes(
  vrf_key_hash: VRFKeyHash, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let vrf_key_hash: RVRFKeyHash = vrf_key_hash.into();
    vrf_key_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_vrf_key_hash_from_bytes(
  data: CData, result: &mut VRFKeyHash, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RVRFKeyHash::from_bytes(bytes.to_vec()).into_result())
      .map(|vrf_key_hash| vrf_key_hash.into())
  })
  .response(result, error)
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct GenesisKeyDelegation {
  genesishash: GenesisHash,
  genesis_delegate_hash: GenesisDelegateHash,
  vrf_keyhash: VRFKeyHash,
}

impl TryFrom<RGenesisKeyDelegation> for GenesisKeyDelegation {
  type Error = CError;

  fn try_from(genesis_key_delegation: RGenesisKeyDelegation) -> Result<Self> {
    genesis_key_delegation
      .genesishash()
      .try_into()
      .map(|genesishash| Self {
        genesishash,
        genesis_delegate_hash: genesis_key_delegation.genesis_delegate_hash().into(),
        vrf_keyhash: genesis_key_delegation.vrf_keyhash().into(),
      })
  }
}

impl From<GenesisKeyDelegation> for RGenesisKeyDelegation {
  fn from(genesis_key_delegation: GenesisKeyDelegation) -> Self {
    Self::new(
      &genesis_key_delegation.genesishash.into(),
      &genesis_key_delegation.genesis_delegate_hash.into(),
      &genesis_key_delegation.vrf_keyhash.into(),
    )
  }
}
