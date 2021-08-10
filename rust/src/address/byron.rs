use crate::bip32_public_key::Bip32PublicKey;
use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use crate::string::*;
use cardano_serialization_lib::address::ByronAddress as RByronAddress;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct ByronAddress(CharPtr);

impl Clone for ByronAddress {
  fn clone(&self) -> Self {
    let s: String = unsafe { self.0.unowned().expect("Bad char pointer").into() };
    Self(s.into_cstr())
  }
}

impl Free for ByronAddress {
  unsafe fn free(&mut self) {
    self.0.free();
  }
}

impl Ptr for ByronAddress {
  type PT = str;

  unsafe fn unowned(&self) -> Result<&str> {
    self.0.unowned()
  }
}

impl From<RByronAddress> for ByronAddress {
  fn from(address: RByronAddress) -> Self {
    Self(address.to_base58().into_cstr())
  }
}

impl TryFrom<ByronAddress> for RByronAddress {
  type Error = CError;

  fn try_from(address: ByronAddress) -> Result<Self> {
    let b58 = unsafe { address.0.unowned()? };
    RByronAddress::from_base58(b58).into_result()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_byron_protocol_magic(
  byron_address: ByronAddress, result: &mut u32, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    byron_address
      .try_into()
      .map(|byron_address: RByronAddress| byron_address.byron_protocol_magic())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_network_id(
  byron_address: ByronAddress, result: &mut u8, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    byron_address
      .try_into()
      .and_then(|byron_address: RByronAddress| byron_address.network_id().into_result())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_is_valid(
  s: CharPtr, result: &mut bool, error: &mut CError,
) -> bool {
  handle_exception_result(|| s.unowned().map(|s| RByronAddress::is_valid(s)))
    .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_icarus_from_key(
  key: Bip32PublicKey, protocol_magic: u32, result: &mut ByronAddress, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    key
      .try_into()
      .map(|key| RByronAddress::icarus_from_key(&key, protocol_magic))
      .map(|byron_address| byron_address.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_from_bytes(
  bytes: CData, byron_address: &mut ByronAddress, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .and_then(|bytes| RByronAddress::from_bytes(bytes.into()).into_result())
      .map(|byron_address| byron_address.into())
  })
  .response(byron_address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_to_bytes(
  byron_address: ByronAddress, bytes: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    byron_address
      .try_into()
      .map(|byron_address: RByronAddress| byron_address.to_bytes().into())
  })
  .response(bytes, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_from_base58(
  b58: CharPtr, address: &mut ByronAddress, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    b58
      .unowned()
      .and_then(|b58| RByronAddress::from_base58(b58).into_result())
      .map(|addr| addr.into())
  })
  .response(address, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_to_base58(
  address: ByronAddress, b58: &mut CharPtr, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    address
      .try_into()
      .map(|addr: RByronAddress| addr.to_base58().into_cstr())
  })
  .response(b58, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_clone(
  address: ByronAddress, result: &mut ByronAddress, error: &mut CError,
) -> bool {
  handle_exception(|| address.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_free(address: &mut ByronAddress) {
  address.free();
}
