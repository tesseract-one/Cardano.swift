use crate::array::*;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use crate::string::{CharPtr, IntoCString};
use serde_json::{from_str, Number as RJsonNumber, Value as RJsonValue};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum JsonNumber {
  PosIntKind(u64),
  NegIntKind(i64),
  FloatKind(f64),
}

impl From<RJsonNumber> for JsonNumber {
  fn from(number: RJsonNumber) -> Self {
    if number.is_u64() {
      Self::PosIntKind(number.as_u64().unwrap())
    } else if number.is_i64() {
      Self::NegIntKind(number.as_i64().unwrap())
    } else if number.is_f64() {
      Self::FloatKind(number.as_f64().unwrap())
    } else {
      panic!("Wrong Number type")
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct WrappedCharPtr(CharPtr);

impl Free for WrappedCharPtr {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

pub type JsonValueMapKeyValue = CKeyValue<WrappedCharPtr, JsonValue>;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct JsonValueMap {
  pub cptr: *const std::os::raw::c_void,
  pub len: usize,
}

impl Free for JsonValueMap {
  unsafe fn free(&mut self) {
    if self.cptr.is_null() {
      return;
    }
    let mut vals = Vec::from_raw_parts(self.cptr as *mut JsonValueMapKeyValue, self.len, self.len);
    self.cptr = std::ptr::null();
    for val in vals.iter_mut() {
      val.free()
    }
  }
}

impl Ptr for JsonValueMap {
  type PT = [JsonValueMapKeyValue];

  unsafe fn unowned(&self) -> Result<&Self::PT> {
    if self.cptr.is_null() {
      Err(CError::NullPtr)
    } else {
      Ok(std::slice::from_raw_parts(
        self.cptr as *const JsonValueMapKeyValue,
        self.len,
      ))
    }
  }
}

impl From<Vec<JsonValueMapKeyValue>> for JsonValueMap {
  fn from(array: Vec<JsonValueMapKeyValue>) -> Self {
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

#[no_mangle]
pub unsafe extern "C" fn cardano_json_value_map_from_array(
  array: *const JsonValueMapKeyValue, len: usize, result: &mut JsonValueMap, error: &mut CError,
) -> bool {
  handle_exception(|| JsonValueMap {
    cptr: array as *const std::os::raw::c_void,
    len,
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_json_value_map_free(json_value_map: &mut JsonValueMap) {
  json_value_map.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum JsonValue {
  NullKind,
  BoolKind(bool),
  NumberKind(JsonNumber),
  StringKind(CharPtr),
  ArrayKind(CArray<JsonValue>),
  ObjectKind(JsonValueMap),
}

impl Free for JsonValue {
  unsafe fn free(&mut self) {
    match self {
      JsonValue::StringKind(string) => string.free(),
      JsonValue::ArrayKind(array) => array.free(),
      JsonValue::ObjectKind(map) => map.free(),
      _ => return,
    }
  }
}

impl From<RJsonValue> for JsonValue {
  fn from(json_value: RJsonValue) -> Self {
    match json_value {
      RJsonValue::Null => Self::NullKind,
      RJsonValue::Bool(bool) => Self::BoolKind(bool),
      RJsonValue::Number(number) => Self::NumberKind(number.into()),
      RJsonValue::String(string) => Self::StringKind(string.into_cstr()),
      RJsonValue::Array(array) => Self::ArrayKind(
        array
          .into_iter()
          .map(|value| value.into())
          .collect::<Vec<JsonValue>>()
          .into(),
      ),
      RJsonValue::Object(map) => Self::ObjectKind(
        map
          .into_iter()
          .map(|(key, value)| (WrappedCharPtr(key.into_cstr()), value.into()).into())
          .collect::<Vec<JsonValueMapKeyValue>>()
          .into(),
      ),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_serde_json_from_str(
  s: CharPtr, result: &mut JsonValue, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    s.unowned()
      .and_then(|s| from_str(s).into_result())
      .map(|value: RJsonValue| value.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_json_value_clone(
  json_value: JsonValue, result: &mut JsonValue, error: &mut CError,
) -> bool {
  handle_exception(|| json_value.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_json_value_free(json_value: &mut JsonValue) {
  json_value.free()
}
