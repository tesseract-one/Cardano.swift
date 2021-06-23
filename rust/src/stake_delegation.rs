use crate::error::CError;
use crate::panic::*;
use crate::stake_credential::Ed25519KeyHash;
use crate::stake_credential::StakeCredential;
use cardano_serialization_lib::StakeDelegation as RStakeDelegation;
use std::convert::TryFrom;
use std::convert::TryInto;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct StakeDelegation {
  stake_credential: StakeCredential,
  pool_keyhash: Ed25519KeyHash,
}

impl From<StakeDelegation> for RStakeDelegation {
  fn from(stake_delegation: StakeDelegation) -> Self {
    let stake_credential = stake_delegation.stake_credential.into();
    let pool_keyhash = stake_delegation.pool_keyhash.into();
    RStakeDelegation::new(&stake_credential, &pool_keyhash)
  }
}

impl TryFrom<RStakeDelegation> for StakeDelegation {
  type Error = CError;

  fn try_from(stake_delegation: RStakeDelegation) -> Result<Self> {
    stake_delegation
      .stake_credential()
      .try_into()
      .zip(stake_delegation.pool_keyhash().try_into())
      .map(|(stake_credential, pool_keyhash)| StakeDelegation {
        stake_credential,
        pool_keyhash,
      })
  }
}
