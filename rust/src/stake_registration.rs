use crate::error::CError;
use crate::panic::*;
use crate::stake_credential::StakeCredential;
use cardano_serialization_lib::StakeRegistration as RStakeRegistration;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct StakeRegistration {
  stake_credential: StakeCredential,
}

impl From<StakeRegistration> for RStakeRegistration {
  fn from(stake_registration: StakeRegistration) -> Self {
    RStakeRegistration::new(&stake_registration.stake_credential.into())
  }
}

impl TryFrom<RStakeRegistration> for StakeRegistration {
  type Error = CError;

  fn try_from(stake_registration: RStakeRegistration) -> Result<Self> {
    stake_registration
      .stake_credential()
      .try_into()
      .map(|stake_credential| Self { stake_credential })
  }
}
