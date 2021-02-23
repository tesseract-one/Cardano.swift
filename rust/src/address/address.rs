use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::Ptr;
use crate::string::*;
use crate::network_info::NetworkId;
use super::addr_type::AddrType;
use super::base::BaseAddress;
use super::enterprise::EnterpriseAddress;
use super::pointer::PointerAddress;
use super::reward::RewardAddress;
use super::byron::{ByronAddress, cardano_byron_address_free};
use cardano_serialization_lib::address::{Address as RAddress};
use std::convert::{TryInto, TryFrom};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum Address {
  Base(BaseAddress),
  Ptr(PointerAddress),
  Enterprise(EnterpriseAddress),
  Reward(RewardAddress),
  Byron(ByronAddress)
}

impl TryFrom<RAddress> for Address {
  type Error = CError;

  fn try_from(address: RAddress) -> Result<Self> {
    let t: AddrType = address.into();
    match t {
      AddrType::Base(base) => base.try_into().map(Address::Base),
      AddrType::Byron(byron) => Ok(Address::Byron(byron.into())),
      AddrType::Ptr(ptr) => ptr.try_into().map(Address::Ptr),
      AddrType::Enterprise(ent) => ent.try_into().map(Address::Enterprise),
      AddrType::Reward(rew) => rew.try_into().map(Address::Reward)
    }
  }
}

impl TryFrom<Address> for RAddress {
  type Error = CError;

  fn try_from(address: Address) -> Result<Self> {
    match address {
      Address::Base(base) => Ok(AddrType::Base(base.into()).into()),
      Address::Byron(byron) => byron.try_into().map(AddrType::Byron).map(|t| t.into()),
      Address::Enterprise(ent) => Ok(AddrType::Enterprise(ent.into()).into()),
      Address::Ptr(ptr) => Ok(AddrType::Ptr(ptr.into()).into()),
      Address::Reward(rew) => Ok(AddrType::Reward(rew.into()).into()),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_to_bytes(
  address: Address, bytes: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    address.try_into().map(|addr: RAddress| addr.to_bytes().into())
  })
  .response(bytes, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_from_bytes(
  bytes: CData, address: &mut Address, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .and_then(|bytes| RAddress::from_bytes(bytes.into()).into_result())
      .and_then(|addr| addr.try_into())
  })
  .response(address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_to_bech32(
  address: Address, prefix: CharPtr, bech32: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    let opt_prefix = if prefix == std::ptr::null() { None } else { Some(prefix) };
    address
      .try_into()
      .zip(opt_prefix.map_or(Ok(None), |p| p.unowned().map(|s| s.to_string().into())))
      .and_then(|(addr, prefix): (RAddress, Option<String>)| addr.to_bech32(prefix).into_result())
      .map(|addr_str| addr_str.into_cstr())
  })
  .response(bech32, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_from_bech32(
  bech32: CharPtr, result: &mut Address, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bech32
      .unowned()
      .and_then(|b32| RAddress::from_bech32(b32).into_result())
      .and_then(|a| a.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_network_id(
  address: Address, result: &mut NetworkId, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    address
      .try_into()
      .and_then(|addr: RAddress| addr.network_id().into_result())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_clone(
  address: Address, result: &mut Address, error: &mut CError
) -> bool {
  handle_exception(|| address.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_free(address: &mut Address) {
  match address {
    &mut Address::Byron(mut byron) => cardano_byron_address_free(&mut byron),
    _ => return
  }
}