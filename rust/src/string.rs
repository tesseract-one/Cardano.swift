use super::ptr::Ptr;
use super::panic::Result;
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

pub type CharPtr = *const c_char;

impl Ptr for CharPtr {
    type PT = str;

    unsafe fn unowned(&self) -> Result<&str> {
        CStr::from_ptr(*self)
            .to_str()
            .map_err(|err| err.into())
    }

    unsafe fn free(&mut self) {
        let _ = CString::from_raw(*self as *mut c_char);
        *self = std::ptr::null();
    }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_charptr_free(ptr: &mut CharPtr) {
  ptr.free();
}

pub trait IntoCString {
  fn into_cstr(&self) -> CharPtr;
}

impl IntoCString for &str {
  fn into_cstr(&self) -> CharPtr {
    CString::new(self.as_bytes()).unwrap().into_raw()
  }
}

impl IntoCString for String {
  fn into_cstr(&self) -> CharPtr {
    CString::new(self.as_bytes()).unwrap().into_raw()
  }
}
