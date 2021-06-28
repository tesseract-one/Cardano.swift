use crate::error::CError;
use crate::linear_fee::Coin;
use crate::multi_asset::MultiAsset;
use crate::option::COption;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::utils::{from_bignum, to_bignum, Value as RValue};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Value {
  coin: Coin,
  multiasset: COption<MultiAsset>,
}

impl Free for Value {
  unsafe fn free(&mut self) {
    self.multiasset.free()
  }
}

impl TryFrom<Value> for RValue {
  type Error = CError;

  fn try_from(value: Value) -> Result<Self> {
    let multiasset: Option<MultiAsset> = value.multiasset.into();
    let mut value = Self::new(&to_bignum(value.coin));
    if let Some(multiasset) = multiasset {
      let multiasset = multiasset.try_into()?;
      value.set_multiasset(&multiasset);
    }
    Ok(value)
  }
}

impl TryFrom<RValue> for Value {
  type Error = CError;

  fn try_from(value: RValue) -> Result<Self> {
    value
      .multiasset()
      .map(|multiasset| multiasset.try_into())
      .transpose()
      .map(|option| Self {
        coin: from_bignum(&value.coin()),
        multiasset: option.into(),
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_checked_add(
  value: Value, rhs: Value, result: &mut Value, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    value
      .try_into()
      .zip(rhs.try_into())
      .and_then(|(value, rhs): (RValue, RValue)| value.checked_add(&rhs).into_result())
      .and_then(|value| value.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_checked_sub(
  value: Value, rhs: Value, result: &mut Value, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    value
      .try_into()
      .zip(rhs.try_into())
      .and_then(|(value, rhs): (RValue, RValue)| value.checked_sub(&rhs).into_result())
      .and_then(|value| value.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_clamped_sub(
  value: Value, rhs: Value, result: &mut Value, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    value
      .try_into()
      .zip(rhs.try_into())
      .map(|(value, rhs): (RValue, RValue)| value.clamped_sub(&rhs))
      .and_then(|value| value.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_compare(
  value: Value, rhs: Value, result: &mut *mut i8, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    value
      .try_into()
      .zip(rhs.try_into())
      .map(|(value, rhs): (RValue, RValue)| value.compare(&rhs))
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_clone(
  value: Value, result: &mut Value, error: &mut CError,
) -> bool {
  handle_exception(|| value.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_value_free(value: &mut Value) {
  value.free();
}
