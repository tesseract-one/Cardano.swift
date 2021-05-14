use super::ptr::{Ptr, Free};
use super::error::CError;
use super::panic::Result;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CData {
  ptr: *const u8,
  len: usize
}

impl Free for CData {
  unsafe fn free(&mut self) {
    if self.ptr.is_null() {
        return;
    }
    let _ = Vec::from_raw_parts(self.ptr as *mut u8, self.len, self.len);
    self.ptr = std::ptr::null();
 }
}

impl Ptr for CData {
  type PT = [u8];

  unsafe fn unowned(&self) -> Result<&[u8]> {
    if self.ptr.is_null() {
      Err(CError::NullPtr)
    } else {
      Ok(std::slice::from_raw_parts(self.ptr, self.len))
    }
  }
}

impl From<&[u8]> for CData {
  fn from(data: &[u8]) -> Self {
    Vec::from(data).into()
  }
}

impl From<Vec<u8>> for CData {
  fn from(data: Vec<u8>) -> Self {
    let len = data.len();
    let mut slice = data.into_boxed_slice();
    let out = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self { ptr: out, len: len }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_data_free(data: &mut CData) {
  data.free();
}