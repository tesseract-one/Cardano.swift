use crate::stake_credential::StakeCredential;
use crate::network_info::NetworkId;
use crate::error::CError;
use crate::panic::*;
use std::convert::{TryInto, TryFrom};
use cardano_serialization_lib::address::{
  BaseAddress as RBaseAddress,
  StakeCredential as RStakeCredential
};

use super::address::Address;

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

#[no_mangle]
pub unsafe extern "C" fn cardano_base_address_new(
  network: NetworkId, payment: StakeCredential, stake: StakeCredential, address: &mut BaseAddress,
  error: &mut CError
) -> bool {
  handle_exception_result(|| RBaseAddress::new(network, &payment.into(), &stake.into()).try_into())
    .response(address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_base_address_to_address(
  base_address: BaseAddress, address: &mut Address, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    let base_address: RBaseAddress = base_address.into();
    base_address.to_address().try_into()
  })
  .response(address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_base_address_from_address(
  address: Address, base_address: &mut BaseAddress, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    address.try_into().and_then(|address| {
      RBaseAddress::from_address(&address).map_or(
        Err("Cannot create BaseAddress from Address".into()),
        |base_address| base_address.try_into(),
      )
    })
  })
  .response(base_address, error)
}
