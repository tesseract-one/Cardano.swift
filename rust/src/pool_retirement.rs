use crate::error::CError;
use crate::panic::*;
use crate::stake_credential::Ed25519KeyHash;
use cardano_serialization_lib::PoolRetirement as RPoolRetirement;
use std::convert::TryFrom;
use std::convert::TryInto;

pub type Epoch = u32;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PoolRetirement {
  pool_keyhash: Ed25519KeyHash,
  epoch: Epoch,
}

impl TryFrom<RPoolRetirement> for PoolRetirement {
  type Error = CError;

  fn try_from(pool_retirement: RPoolRetirement) -> Result<Self> {
    pool_retirement
      .pool_keyhash()
      .try_into()
      .map(|pool_keyhash| Self {
        pool_keyhash,
        epoch: pool_retirement.epoch(),
      })
  }
}

impl From<PoolRetirement> for RPoolRetirement {
  fn from(pool_retirement: PoolRetirement) -> Self {
    RPoolRetirement::new(&pool_retirement.pool_keyhash.into(), pool_retirement.epoch)
  }
}
