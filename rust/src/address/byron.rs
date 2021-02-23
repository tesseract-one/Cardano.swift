use crate::string::*;
use crate::panic::*;
use crate::ptr::Ptr;
use crate::error::CError;
use std::convert::{TryInto, TryFrom};
use cardano_serialization_lib::address::{ByronAddress as RByronAddress};

#[repr(C)]
#[derive(Copy)]
pub struct ByronAddress(CharPtr);

impl Clone for ByronAddress {
  fn clone(&self) -> Self {
    let s: String = unsafe { self.0.unowned().expect("Bad char pointer").into() };
    Self(s.into_cstr())
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
pub unsafe extern "C" fn cardano_byron_address_from_base58(
  b58: CharPtr, address: &mut ByronAddress, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    b58.unowned()
      .and_then(|b58| RByronAddress::from_base58(b58).into_result())
      .map(|addr| addr.into())
  }).response(address, error)
}


#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_to_base58(
  address: ByronAddress, b58: &mut CharPtr, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    address
      .try_into()
      .map(|addr: RByronAddress| addr.to_base58().into_cstr())
  }).response(b58, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_clone(
  address: ByronAddress, result: &mut ByronAddress, error: &mut CError
) -> bool {
  handle_exception(|| address.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_byron_address_free(address: &mut ByronAddress) {
  address.0.free();
}