use crate::ptr::*;

#[repr(C)]
#[derive(Copy, Clone)]
pub enum COption<T> {
  Some(T),
  None,
}

impl<T: Free> Free for COption<T> {
  unsafe fn free(&mut self) {
    match self {
      COption::Some(value) => value.free(),
      COption::None => (),
    }
  }
}

impl<T> From<Option<T>> for COption<T> {
  fn from(option: Option<T>) -> Self {
    match option {
      Some(value) => COption::Some(value),
      None => COption::None,
    }
  }
}

impl<T> From<COption<T>> for Option<T> {
  fn from(option: COption<T>) -> Self {
    match option {
      COption::Some(value) => Some(value),
      COption::None => None,
    }
  }
}
