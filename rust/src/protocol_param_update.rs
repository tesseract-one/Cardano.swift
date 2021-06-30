use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::ProtocolParamUpdate as RProtocolParamUpdate;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct ProtocolParamUpdate(CData);

impl Clone for ProtocolParamUpdate {
  fn clone(&self) -> Self {
    let bytes = unsafe { self.0.unowned().expect("Bad bytes pointer") };
    Self(bytes.into())
  }
}

impl Free for ProtocolParamUpdate {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<ProtocolParamUpdate> for RProtocolParamUpdate {
  type Error = CError;

  fn try_from(protocol_param_update: ProtocolParamUpdate) -> Result<Self> {
    let bytes = unsafe { protocol_param_update.0.unowned()? };
    Self::from_bytes(bytes.to_vec()).into_result()
  }
}

impl From<RProtocolParamUpdate> for ProtocolParamUpdate {
  fn from(protocol_param_update: RProtocolParamUpdate) -> Self {
    Self(protocol_param_update.to_bytes().into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_from_bytes(
  data: CData, result: &mut ProtocolParamUpdate, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RProtocolParamUpdate::from_bytes(bytes.to_vec()).into_result())
      .map(|protocol_param_update| protocol_param_update.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_to_bytes(
  protocol_param_update: ProtocolParamUpdate, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    protocol_param_update
      .try_into()
      .map(|protocol_param_update: RProtocolParamUpdate| protocol_param_update.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_clone(
  protocol_param_update: ProtocolParamUpdate, result: &mut ProtocolParamUpdate, error: &mut CError,
) -> bool {
  handle_exception(|| protocol_param_update.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_free(
  protocol_param_update: &mut ProtocolParamUpdate,
) {
  protocol_param_update.free()
}
