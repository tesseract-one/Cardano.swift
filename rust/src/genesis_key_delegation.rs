use cardano_serialization_lib::{
  crypto::{
    GenesisDelegateHash as RGenesisDelegateHash, GenesisHash as RGenesisHash,
    VRFKeyHash as RVRFKeyHash,
  },
  GenesisKeyDelegation as RGenesisKeyDelegation,
};
use std::convert::TryInto;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct GenesisHash([u8; 28]);

impl From<RGenesisHash> for GenesisHash {
  fn from(hash: RGenesisHash) -> Self {
    Self(hash.to_bytes().try_into().unwrap())
  }
}

impl From<GenesisHash> for RGenesisHash {
  fn from(hash: GenesisHash) -> Self {
    hash.0.into()
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

impl From<RGenesisKeyDelegation> for GenesisKeyDelegation {
  fn from(genesis_key_delegation: RGenesisKeyDelegation) -> Self {
    Self {
      genesishash: genesis_key_delegation.genesishash().into(),
      genesis_delegate_hash: genesis_key_delegation.genesis_delegate_hash().into(),
      vrf_keyhash: genesis_key_delegation.vrf_keyhash().into(),
    }
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
