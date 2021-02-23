use super::string::*;
use super::ptr::Ptr;
use cardano_serialization_lib::error::*;

#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub enum CError {
    NullPtr,
    DataLengthMismatch,
    Panic(CharPtr),
    Utf8Error(CharPtr),
    DeserializeError(CharPtr),
    Error(CharPtr)
}

impl CError {
    pub unsafe fn free(self) {
        match self {
            CError::Panic(mut ptr) => ptr.free(),
            CError::Utf8Error(mut ptr) => ptr.free(),
            CError::DeserializeError(mut ptr) => ptr.free(),
            CError::Error(mut ptr) => ptr.free(),
            _ => return
        }
    }
}

impl From<std::str::Utf8Error> for CError {
    fn from(error: std::str::Utf8Error) -> Self {
        Self::Utf8Error(format!("{}", error).into_cstr())
    }
}

impl From<DeserializeError> for CError {
    fn from(error: DeserializeError) -> Self {
        Self::DeserializeError(format!("{}", error).into_cstr())
    }
}

impl From<JsError> for CError {
    fn from(error: JsError) -> Self {
        Self::Error(format!("{}", error).into_cstr())
    }
}

impl From<String> for CError {
    fn from(string: String) -> Self {
        Self::Error(string.into_cstr())
    }
}

impl From<&str> for CError {
    fn from(string: &str) -> Self {
        Self::Error(string.into_cstr())
    }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_error_free(err: &mut CError) {
    err.free();
}