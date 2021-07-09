use crate::error::CError;
use crate::panic::Result;
use crate::ptr::*;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CPointer<T: Free>(*const T);

impl<T: Free> CPointer<T> {
  pub fn new(pointer: &T) -> Self {
    CPointer(pointer)
  }
}

impl<T: Free> Free for CPointer<T> {
  unsafe fn free(&mut self) {
    if self.0.is_null() {
      return;
    }
    (*(self.0 as *mut T)).free();
    self.0 = std::ptr::null();
  }
}

impl<T: Free> Ptr for CPointer<T> {
  type PT = T;

  unsafe fn unowned(&self) -> Result<&T> {
    self.0.as_ref().ok_or(CError::NullPtr)
  }
}
