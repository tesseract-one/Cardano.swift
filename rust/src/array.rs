use super::ptr::*;
use super::error::CError;
use super::panic::Result;
use std::collections::{BTreeMap, HashMap};

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

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CKeyValue<K, V> {
  pub key: K,
  pub val: V
}

impl<K: Free, V: Free> Free for CKeyValue<K, V> {
  unsafe fn free(&mut self) {
    self.key.free(); self.val.free();
  }
}

impl<K, V> From<(K, V)> for CKeyValue<K, V> {
  fn from(tuple: (K, V)) -> Self {
    Self { key: tuple.0, val: tuple.1 }
  }
}

impl<K, V> From<CKeyValue<K, V>> for (K, V) {
  fn from(kv: CKeyValue<K, V>) -> Self {
    (kv.key, kv.val)
  }
}

pub trait AsHashMap {
  type Key: Free + std::hash::Hash + Eq + Clone;
  type Value: Free + Clone;

  unsafe fn as_hash_map(&self) -> Result<HashMap<Self::Key, Self::Value>>;
}

pub trait AsBTreeMap {
  type Key: Free + Ord;
  type Value: Free;

  unsafe fn as_btree_map(&self) -> Result<BTreeMap<Self::Key, Self::Value>>;
}

impl<K: Free + Ord + Clone, V: Free + Clone> AsBTreeMap for CArray<CKeyValue<K, V>> {
  type Key = K;
  type Value = V;

  unsafe fn as_btree_map(&self) -> Result<BTreeMap<K, V>> {
    self.unowned().map(|sl| sl.into_iter().cloned().map(|kv| kv.into()).collect())
  }
}

impl<K: Free + std::hash::Hash + Eq + Clone, V: Free + Clone> AsHashMap for CArray<CKeyValue<K,V>> {
  type Key = K;
  type Value = V;

  unsafe fn as_hash_map(&self) -> Result<HashMap<K, V>> {
    self.unowned().map(|sl| sl.into_iter().cloned().map(|kv| kv.into()).collect())
  }
}

impl <K1, K2, V1, V2> From<BTreeMap<K2, V2>> for CArray<CKeyValue<K1, V1>> 
  where
    K1: Free, K2: Into<K1>, V1: Free, V2: Into<V1>
{
  fn from(map: BTreeMap<K2, V2>) -> Self {
    let kvs: Vec<CKeyValue<K1, V1>> = map.into_iter().map(|(k, v)| (k.into(), v.into()).into()).collect();
    let len = kvs.len();
    let mut slice = kvs.into_boxed_slice();
    let ptr = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self { ptr, len }
  }
}

impl <K1, K2, V1, V2> From<HashMap<K2, V2>> for CArray<CKeyValue<K1, V1>> 
  where
    K1: Free, K2: Into<K1>, V1: Free, V2: Into<V1>
{
  fn from(map: HashMap<K2, V2>) -> Self {
    let kvs: Vec<CKeyValue<K1, V1>> = map.into_iter().map(|(k, v)| (k.into(), v.into()).into()).collect();
    let len = kvs.len();
    let mut slice = kvs.into_boxed_slice();
    let ptr = slice.as_mut_ptr();
    std::mem::forget(slice);
    Self { ptr, len }
  }
}
