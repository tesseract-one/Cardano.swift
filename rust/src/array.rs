use super::ptr::*;
use super::error::CError;
use super::panic::Result;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CArray<Value: Free> {
  ptr: *const Value,
  len: usize
}

impl<Value: Free> Free for CArray<Value> {
  unsafe fn free(&mut self) {
    if self.ptr.is_null() {
        return;
    }
    let mut vals = Vec::from_raw_parts(self.ptr as *mut Value, self.len, self.len);
    self.ptr = std::ptr::null();
    for val in vals.iter_mut() {
      val.free()
    }
 }
}

impl<Value: Free> Ptr for CArray<Value> {
  type PT = [Value];

  unsafe fn unowned(&self) -> Result<&[Value]> {
    if self.ptr.is_null() {
      Err(CError::NullPtr)
    } else {
      Ok(std::slice::from_raw_parts(self.ptr, self.len))
    }
  }
}

impl <V1: Free, V2: Into<V1> + Clone> From<&[V2]> for CArray<V1> {
  fn from(array: &[V2]) -> Self {
    Vec::from(array).into()
  }
}

impl <V1: Free, V2: Into<V1>> From<Vec<V2>> for CArray<V1> {
  fn from(array: Vec<V2>) -> Self {
    let mapped: Vec<V1> = array.into_iter().map(|v| v.into()).collect();
    let len = mapped.len();
    let mut slice = mapped.into_boxed_slice();
    let out = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self { ptr: out, len: len }
  }
}
