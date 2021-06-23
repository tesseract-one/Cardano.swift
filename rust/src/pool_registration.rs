use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::PoolRegistration as RPoolRegistration;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct PoolRegistration(CData);

impl Clone for PoolRegistration {
  fn clone(&self) -> Self {
    let bytes = unsafe { self.0.unowned().expect("Bad bytes pointer") };
    Self(bytes.into())
  }
}

impl Free for PoolRegistration {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<PoolRegistration> for RPoolRegistration {
  type Error = CError;

  fn try_from(pool_registration: PoolRegistration) -> Result<Self> {
    let bytes = unsafe { pool_registration.0.unowned()? };
    Self::from_bytes(bytes.to_vec()).into_result()
  }
}

impl From<RPoolRegistration> for PoolRegistration {
  fn from(pool_registration: RPoolRegistration) -> Self {
    Self(pool_registration.to_bytes().into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_from_bytes(
  data: CData, result: &mut PoolRegistration, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RPoolRegistration::from_bytes(bytes.to_vec()).into_result())
      .map(|pool_registration| pool_registration.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_to_bytes(
  pool_registration: PoolRegistration, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    pool_registration
      .try_into()
      .map(|pool_registration: RPoolRegistration| pool_registration.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_clone(
  pool_registration: PoolRegistration, result: &mut PoolRegistration, error: &mut CError,
) -> bool {
  handle_exception(|| pool_registration.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_free(pool_registration: &mut PoolRegistration) {
  pool_registration.free()
}
