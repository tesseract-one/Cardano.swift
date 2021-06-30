use super::panic::*;
use crate::error::CError;

pub trait Free {
  unsafe fn free(&mut self);
}

pub trait Ptr: Free {
  type PT: ?Sized;

  unsafe fn unowned(&self) -> Result<&Self::PT>;
}

impl Free for u64 {
  unsafe fn free(&mut self) {}
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CPointer<T: Free>(pub(crate) *const T);

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

// pub trait SizedPtr: Sized {
//     type SPT: Sized;

//     fn empty() -> Self;
//     fn ptr(&self) -> *mut c_void;
//     fn set_ptr(&mut self, ptr: *mut c_void);

//     fn new(value: Self::SPT) -> Self {
//         let mut s = Self::empty();
//         s.set_ptr(Box::into_raw(Box::new(value)).cast::<c_void>());
//         s
//     }

//     unsafe fn unowned(&self) -> Result<&Self::SPT> {
//         self.ptr()
//             .cast::<Self::SPT>()
//             .as_ref()
//             .ok_or(CError::NullPtr)
//     }

//     unsafe fn owned(mut self) -> Result<Self::SPT> {
//         if self.ptr().is_null() {
//             Err(CError::NullPtr)
//         } else {
//             let boxed = Box::from_raw(self.ptr().cast::<Self::SPT>());
//             self.set_ptr(std::ptr::null_mut());
//             Ok(*boxed)
//         }
//     }

//     unsafe fn free(&mut self) {
//         if !self.ptr().is_null() {
//            let _ = Box::from_raw(self.ptr().cast::<Self::SPT>());
//            self.set_ptr(std::ptr::null_mut());
//         }
//     }
// }
