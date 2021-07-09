use crate::array::*;
use crate::error::CError;
use crate::general_transaction_metadata::TransactionMetadatum;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::metadata::MetadataMap as RMetadataMap;
use std::convert::{TryFrom, TryInto};

pub type MetadataMapKeyValue = CKeyValue<TransactionMetadatum, TransactionMetadatum>;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct MetadataMap {
  pub ptr: *const std::os::raw::c_void,
  pub len: usize
}

impl Free for MetadataMap {
  unsafe fn free(&mut self) {
    if self.ptr.is_null() {
      return;
    }
    let mut vals = Vec::from_raw_parts(self.ptr as *mut MetadataMapKeyValue, self.len, self.len);
    self.ptr = std::ptr::null();
    for val in vals.iter_mut() {
      val.free()
    }
  }
}

impl Ptr for MetadataMap {
  type PT = [MetadataMapKeyValue];

  unsafe fn unowned(&self) -> Result<&[MetadataMapKeyValue]> {
    if self.ptr.is_null() {
      Err(CError::NullPtr)
    } else {
      Ok(std::slice::from_raw_parts(self.ptr as *const MetadataMapKeyValue, self.len))
    }
  }
}

impl TryFrom<MetadataMap> for RMetadataMap {
  type Error = CError;

  fn try_from(metadata_map: MetadataMap) -> Result<Self> {
    let vec = unsafe { metadata_map.unowned()? };
    let mut metadata_map = RMetadataMap::new();
    for ckv in vec.to_vec() {
      let (tm_key, tm_value) = ckv.into();
      metadata_map.insert(&tm_key.try_into()?, &tm_value.try_into()?);
    }
    Ok(metadata_map)
  }
}

impl From<Vec<MetadataMapKeyValue>> for MetadataMap {
  fn from(array: Vec<MetadataMapKeyValue>) -> Self {
    let len = array.len();
    let mut slice = array.into_boxed_slice();
    let out = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self { ptr: out as *const std::os::raw::c_void, len: len }
  }
}

impl TryFrom<RMetadataMap> for MetadataMap {
  type Error = CError;

  fn try_from(metadata_map: RMetadataMap) -> Result<Self> {
    Ok(metadata_map.keys()).and_then(|keys| {
      (0..keys.len())
        .map(|index| keys.get(index))
        .map(|tm_key| {
          metadata_map
            .get(&tm_key)
            .into_result()
            .and_then(|tm_value| tm_value.try_into())
            .zip(tm_key.try_into())
            .map(|(tm_value, tm_key)| (tm_key, tm_value).into())
        })
        .collect::<Result<Vec<MetadataMapKeyValue>>>()
        .map(|metadata_map| metadata_map.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_metadata_map_from_array(
  array: *const MetadataMapKeyValue, len: usize,
  result: &mut MetadataMap, error: &mut CError
) -> bool {
  handle_exception(|| {
    MetadataMap { ptr: array as *const std::os::raw::c_void, len: len }
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_metadata_map_free(metadata_map: &mut MetadataMap) {
  metadata_map.free();
}
