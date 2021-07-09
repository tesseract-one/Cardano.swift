use super::error::CError;
use super::panic::*;
use cardano_serialization_lib::{
  fees::LinearFee as RLinearFee,
  utils::{from_bignum, to_bignum},
};

pub type Coin = u64;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct LinearFee {
  pub constant: Coin,
  pub coefficient: Coin,
}

impl From<LinearFee> for RLinearFee {
  fn from(linear_fee: LinearFee) -> Self {
    Self::new(
      &to_bignum(linear_fee.coefficient),
      &to_bignum(linear_fee.constant),
    )
  }
}

impl From<RLinearFee> for LinearFee {
  fn from(linear_fee: RLinearFee) -> Self {
    Self {
      constant: from_bignum(&linear_fee.constant()),
      coefficient: from_bignum(&linear_fee.coefficient()),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_linear_fee_new(
  coefficient: Coin, constant: Coin, result: &mut LinearFee, error: &mut CError,
) -> bool {
  handle_exception(|| RLinearFee::new(&to_bignum(coefficient), &to_bignum(constant)).into())
    .response(result, error)
}
