use std::convert::TryFrom;

use num_bigint::{BigInt, Sign as RSign};

use crate::{array::CArray, error::CError, panic::Result, ptr::*};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CInt128 {
  w1: i64,
  w2: u64,
}

impl From<i128> for CInt128 {
  fn from(int: i128) -> Self {
    Self {
      w1: (int >> 64) as i64,
      w2: ((int as u128) & (std::u64::MAX as u128)) as u64,
    }
  }
}

impl Into<i128> for CInt128 {
  fn into(self: CInt128) -> i128 {
    (self.w1 as i128) << 64 | self.w2 as i128
  }
}

#[repr(C)]
pub struct CUInt128 {
  w1: u64,
  w2: u64,
}

impl From<u128> for CUInt128 {
  fn from(int: u128) -> Self {
    Self {
      w1: (int >> 64) as u64,
      w2: (int & (std::u64::MAX as u128)) as u64,
    }
  }
}

impl Into<u128> for CUInt128 {
  fn into(self: CUInt128) -> u128 {
    (self.w1 as u128) << 64 | self.w2 as u128
  }
}

#[no_mangle]
pub unsafe extern "C" fn test_int_zero(int: CInt128) -> bool {
  let rust: i128 = int.into();
  rust == 0
}

#[no_mangle]
pub unsafe extern "C" fn test_uint_zero(int: CUInt128) -> bool {
  let rust: u128 = int.into();
  rust == 0
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum Sign {
  Minus,
  NoSign,
  Plus,
}

impl From<Sign> for RSign {
  fn from(sign: Sign) -> Self {
    match sign {
      Sign::Minus => Self::Minus,
      Sign::NoSign => Self::NoSign,
      Sign::Plus => Self::Plus,
    }
  }
}

impl From<RSign> for Sign {
  fn from(sign: RSign) -> Self {
    match sign {
      RSign::Minus => Self::Minus,
      RSign::NoSign => Self::NoSign,
      RSign::Plus => Self::Plus,
    }
  }
}

impl Free for u32 {
  unsafe fn free(&mut self) {}
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CBigInt {
  sign: Sign,
  data: CArray<u32>,
}

impl Free for CBigInt {
  unsafe fn free(&mut self) {
    self.data.free()
  }
}

impl TryFrom<CBigInt> for BigInt {
  type Error = CError;

  fn try_from(big_int: CBigInt) -> Result<Self> {
    let digits = unsafe { big_int.data.unowned()? };
    Ok(Self::new(big_int.sign.into(), digits.to_vec()))
  }
}

impl From<BigInt> for CBigInt {
  fn from(big_int: BigInt) -> Self {
    Self {
      sign: big_int.sign().into(),
      data: big_int.magnitude().to_u32_digits().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_big_int_free(big_int: &mut CBigInt) {
  big_int.free()
}
