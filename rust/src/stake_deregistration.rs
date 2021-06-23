use std::convert::{TryFrom, TryInto};
use cardano_serialization_lib::StakeDeregistration as RStakeDeregistration;
use crate::error::CError;
use crate::panic::*;
use crate::stake_credential::StakeCredential;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct StakeDeregistration {
  stake_credential: StakeCredential
}

impl From<StakeDeregistration> for RStakeDeregistration {
  fn from(stake_deregistration: StakeDeregistration) -> Self {
    RStakeDeregistration::new(&stake_deregistration.stake_credential.into())
  }
}

impl TryFrom<RStakeDeregistration> for StakeDeregistration {
  type Error = CError;

  fn try_from(stake_deregistration: RStakeDeregistration) -> Result<Self> {
    stake_deregistration
      .stake_credential()
      .try_into()
      .map(|stake_credential| Self { stake_credential })
  }
}
