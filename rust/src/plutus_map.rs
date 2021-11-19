use std::convert::{TryFrom, TryInto};

use cardano_serialization_lib::plutus::PlutusMap as RPlutusMap;

use crate::{
  array::CKeyValue, error::CError, panic::*, ptr::*, transaction_witness_set::PlutusData,
};

pub type PlutusMapKeyValue = CKeyValue<PlutusData, PlutusData>;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PlutusMap {
  pub cptr: *const std::os::raw::c_void,
  pub len: usize,
}

impl Free for PlutusMap {
  unsafe fn free(&mut self) {
    if self.cptr.is_null() {
      return;
    }
    let mut vals = Vec::from_raw_parts(self.cptr as *mut PlutusMapKeyValue, self.len, self.len);
    self.cptr = std::ptr::null();
    for val in vals.iter_mut() {
      val.free()
    }
  }
}

impl Ptr for PlutusMap {
  type PT = [PlutusMapKeyValue];

  unsafe fn unowned(&self) -> Result<&[PlutusMapKeyValue]> {
    if self.cptr.is_null() {
      Err(CError::NullPtr)
    } else {
      Ok(std::slice::from_raw_parts(
        self.cptr as *const PlutusMapKeyValue,
        self.len,
      ))
    }
  }
}

impl From<Vec<PlutusMapKeyValue>> for PlutusMap {
  fn from(array: Vec<PlutusMapKeyValue>) -> Self {
    let len = array.len();
    let mut slice = array.into_boxed_slice();
    let out = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self {
      cptr: out as *const std::os::raw::c_void,
      len,
    }
  }
}

impl TryFrom<PlutusMap> for RPlutusMap {
  type Error = CError;

  fn try_from(plutus_map: PlutusMap) -> Result<Self> {
    let vec = unsafe { plutus_map.unowned()? };
    Ok(Self::new()).and_then(|mut plutus_map| {
      vec
        .iter()
        .map(|&ckv| ckv.into())
        .map(|(key, value)| {
          key
            .try_into()
            .zip(value.try_into())
            .map(|(key, value)| plutus_map.insert(&key, &value))
        })
        .collect::<Result<Vec<_>>>()
        .map(|_| plutus_map)
    })
  }
}

impl TryFrom<RPlutusMap> for PlutusMap {
  type Error = CError;

  fn try_from(plutus_map: RPlutusMap) -> Result<Self> {
    Ok(plutus_map.keys()).and_then(|keys| {
      (0..keys.len())
        .map(|index| keys.get(index))
        .map(|pd_key| {
          plutus_map
            .get(&pd_key)
            .ok_or("Cannot get PlutusData from PlutusMap".into())
            .and_then(|pd_value| pd_value.try_into())
            .zip(pd_key.try_into())
            .map(|(pd_value, pd_key)| (pd_key, pd_value).into())
        })
        .collect::<Result<Vec<PlutusMapKeyValue>>>()
        .map(|plutus_map| plutus_map.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_plutus_map_from_array(
  array: *const PlutusMapKeyValue, len: usize, result: &mut PlutusMap, error: &mut CError,
) -> bool {
  handle_exception(|| PlutusMap {
    cptr: array as *const std::os::raw::c_void,
    len,
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_plutus_map_free(plutus_map: &mut PlutusMap) {
  plutus_map.free()
}
