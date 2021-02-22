use super::data::CData;
use super::error::CError;
use super::panic::*;
use super::ptr::*;
use super::string::*;
use cardano_serialization_lib::address::Address;
use std::ffi::c_void;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CAddress(*mut c_void);

impl SizedPtr for CAddress {
  type SPT = Address;

  fn empty() -> Self {
    Self(std::ptr::null_mut())
  }

  fn ptr(&self) -> *mut c_void {
    self.0
  }

  fn set_ptr(&mut self, ptr: *mut c_void) {
    self.0 = ptr;
  }
}

pub type NetworkId = u8;

#[no_mangle]
pub unsafe extern "C" fn cardano_address_to_bytes(
  address: CAddress, bytes: &mut CData, error: &mut CError
) -> bool {
  handle_exception_result(|| address.unowned().map(|addr| addr.to_bytes().into()))
    .response(bytes, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_from_bytes(
  bytes: CData, address: &mut CAddress, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .and_then(|bytes| Address::from_bytes(bytes.into()).into_result())
      .map(CAddress::new)
  })
  .response(address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_to_bech32(
  address: CAddress, prefix: CharPtr, bech32: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    let opt_prefix = if prefix == std::ptr::null() { None } else { Some(prefix) };
    address
      .unowned()
      .zip(opt_prefix.map_or(Ok(None), |p| p.unowned().map(|s| s.to_string().into())))
      .and_then(|(addr, prefix)| addr.to_bech32(prefix).into_result())
      .map(|addr_str| addr_str.into_cstr())
  })
  .response(bech32, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_from_bech32(
  bech32: CharPtr, result: &mut CAddress, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    bech32
      .unowned()
      .and_then(|b32| Address::from_bech32(b32).into_result())
      .map(CAddress::new)
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_network_id(
  address: CAddress, result: &mut NetworkId, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    address.unowned()
      .and_then(|addr| addr.network_id().into_result())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_address_free(address: &mut CAddress) {
  address.free();
}