use crate::stake_credential::StakeCredential;
use crate::network_info::NetworkId;
use crate::error::CError;
use crate::panic::Result;
use std::convert::{TryInto, TryFrom};

use cardano_serialization_lib::address::{
  EnterpriseAddress as REnterpriseAddress,
  StakeCredential as RStakeCredential
};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct EnterpriseAddress {
  network: NetworkId,
  payment: StakeCredential
}

struct MEAddress {
  network: NetworkId,
  payment: RStakeCredential
}

impl TryFrom<REnterpriseAddress> for EnterpriseAddress {
  type Error = CError;

  fn try_from(address: REnterpriseAddress) -> Result<Self> {
    let maddress: MEAddress = unsafe { std::mem::transmute(address) };
    let payment = maddress.payment.try_into()?;
    Ok(Self { network: maddress.network, payment: payment })
  }
}

impl From<EnterpriseAddress> for REnterpriseAddress {
  fn from(address: EnterpriseAddress) -> Self {
    Self::new(address.network, &address.payment.into())
  }
}
