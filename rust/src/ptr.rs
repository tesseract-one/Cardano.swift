use std::ffi::c_void;
use super::panic::*;
use super::error::CError;

pub trait Ptr {
    type PT: ?Sized;

    unsafe fn unowned(&self) -> Result<&Self::PT>;
    unsafe fn free(&mut self);
}

pub trait SizedPtr: Sized {
    type SPT: Sized;

    fn empty() -> Self;
    fn ptr(&self) -> *mut c_void;
    fn set_ptr(&mut self, ptr: *mut c_void);

    fn new(value: Self::SPT) -> Self {
        let mut s = Self::empty();
        s.set_ptr(Box::into_raw(Box::new(value)).cast::<c_void>());
        s
    }

    unsafe fn unowned(&self) -> Result<&Self::SPT> {
        self.ptr()
            .cast::<Self::SPT>()
            .as_ref()
            .ok_or(CError::NullPtr)
    }

    unsafe fn owned(mut self) -> Result<Self::SPT> {
        if self.ptr().is_null() {
            Err(CError::NullPtr)
        } else {
            let boxed = Box::from_raw(self.ptr().cast::<Self::SPT>());
            self.set_ptr(std::ptr::null_mut());
            Ok(*boxed)
        }
    }

    unsafe fn free(&mut self) {
        if !self.ptr().is_null() {
           let _ = Box::from_raw(self.ptr().cast::<Self::SPT>());
           self.set_ptr(std::ptr::null_mut());
        }
    }
}

