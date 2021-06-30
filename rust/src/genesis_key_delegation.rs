use cardano_serialization_lib::{
  crypto::{
    GenesisDelegateHash as RGenesisDelegateHash, GenesisHash as RGenesisHash,
    VRFKeyHash as RVRFKeyHash,
  },
  GenesisKeyDelegation as RGenesisKeyDelegation,
};
use std::convert::{TryFrom, TryInto};

use crate::{error::CError, panic::Result};

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
