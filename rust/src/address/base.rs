use crate::stake_credential::StakeCredential;
use crate::network_info::NetworkId;
use crate::error::CError;
use crate::panic::*;
use std::convert::{TryInto, TryFrom};
use cardano_serialization_lib::address::{
  BaseAddress as RBaseAddress,
  StakeCredential as RStakeCredential
};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct BaseAddress {
  network: NetworkId,
  payment: StakeCredential,
  stake: StakeCredential
}

// For transmute black magick
struct MBAddress {
  network: u8,
  payment: RStakeCredential,
  stake: RStakeCredential
}

impl TryFrom<RBaseAddress> for BaseAddress {
  type Error = CError;

  fn try_from(address: RBaseAddress) -> Result<Self> {
    let mbaddr: MBAddress = unsafe { std::mem::transmute(address) };
    let payment = mbaddr.payment.try_into()?;
    let stake = mbaddr.stake.try_into()?;
    Ok(Self { network: mbaddr.network, payment: payment, stake: stake })
  }
}

impl From<BaseAddress> for RBaseAddress {
  fn from(address: BaseAddress) -> Self {
    RBaseAddress::new(
      address.network,
      &address.payment.into(),
      &address.stake.into()
    )
  }
}
