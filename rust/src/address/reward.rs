use crate::error::CError;
use crate::network_info::NetworkId;
use crate::panic::Result;
use crate::stake_credential::StakeCredential;
use std::convert::{TryFrom, TryInto};

use cardano_serialization_lib::address::{
  RewardAddress as RRewardAddress, StakeCredential as RStakeCredential,
};

#[repr(C)]
#[derive(Copy, Clone, Hash, PartialEq, Eq)]
pub struct RewardAddress {
  network: NetworkId,
  payment: StakeCredential,
}

struct MRAddress {
  network: u8,
  payment: RStakeCredential,
}

impl TryFrom<RRewardAddress> for RewardAddress {
  type Error = CError;

  fn try_from(address: RRewardAddress) -> Result<Self> {
    let maddress: MRAddress = unsafe { std::mem::transmute(address) };
    let payment = maddress.payment.try_into()?;
    Ok(Self {
      network: maddress.network,
      payment: payment,
    })
  }
}

impl From<RewardAddress> for RRewardAddress {
  fn from(address: RewardAddress) -> Self {
    Self::new(address.network, &address.payment.into())
  }
}
