
#[repr(C)]
pub struct CInt128 {
    w1: i64,
    w2: u64
}

impl From<i128> for CInt128 {
    fn from(int: i128) -> Self {
        Self {
            w1: (int >> 64) as i64,
            w2: ((int as u128) & (std::u64::MAX as u128)) as u64
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
    w2: u64
}

impl From<u128> for CUInt128 {
    fn from(int: u128) -> Self {
        Self {
            w1: (int >> 64) as u64,
            w2: (int & (std::u64::MAX as u128)) as u64
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