use super::ptr::*;
use super::error::CError;
use super::panic::Result;
use std::collections::{BTreeMap, HashMap};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct CMap<Key: Free, Value: Free> {
  keys_ptr: *const Key,
  values_ptr: *const Value,
  len: usize
}

impl<Key: Free, Value: Free> Free for CMap<Key, Value> {
  unsafe fn free(&mut self) {
    if !self.keys_ptr.is_null() {
      let mut keys = Vec::from_raw_parts(self.keys_ptr as *mut Key, self.len, self.len);
      self.keys_ptr = std::ptr::null();
      for key in keys.iter_mut() {
        key.free()
      }
    }
    if !self.values_ptr.is_null() {
      let mut vals = Vec::from_raw_parts(self.values_ptr as *mut Value, self.len, self.len);
      self.values_ptr = std::ptr::null();
      for val in vals.iter_mut() {
        val.free()
      }
    }
  }
}

pub trait AsUnownedHashMap {
  type Key: Free + std::hash::Hash + Eq;
  type Value: Free;

  unsafe fn unowned_hash_map(&self) -> Result<HashMap<&Self::Key, &Self::Value>>;
}

pub trait AsUnownedBTreeMap {
  type Key: Free + Ord;
  type Value: Free;

  unsafe fn unowned_btree_map(&self) -> Result<BTreeMap<&Self::Key, &Self::Value>>;
}


impl<K: Free + Ord, V: Free> AsUnownedBTreeMap for CMap<K, V> {
  type Key = K;
  type Value = V;

  unsafe fn unowned_btree_map(&self) -> Result<BTreeMap<&K, &V>> {
    if self.keys_ptr.is_null() || self.values_ptr.is_null() {
      Err(CError::NullPtr)
    } else {
      let keys = std::slice::from_raw_parts(self.keys_ptr, self.len);
      let values = std::slice::from_raw_parts(self.values_ptr, self.len);
      Ok(keys.iter().zip(values).collect())
    }
  }
}

impl<K: Free + std::hash::Hash + Eq, V: Free> AsUnownedHashMap for CMap<K, V> {
  type Key = K;
  type Value = V;

  unsafe fn unowned_hash_map(&self) -> Result<HashMap<&K, &V>> {
    if self.keys_ptr.is_null() || self.values_ptr.is_null() {
      Err(CError::NullPtr)
    } else {
      let keys = std::slice::from_raw_parts(self.keys_ptr, self.len);
      let values = std::slice::from_raw_parts(self.values_ptr, self.len);
      Ok(keys.iter().zip(values).collect())
    }
  }
}

impl <K1, K2, V1, V2> From<BTreeMap<K2, V2>> for CMap<K1, V1> 
  where
    K1: Free, K2: Into<K1> + Clone, V1: Free, V2: Into<V1> + Clone
{
  fn from(map: BTreeMap<K2, V2>) -> Self {
    let keys: Vec<K1> = map.keys().cloned().map(|k| k.into()).collect();
    let values: Vec<V1> = map.values().cloned().map(|v| v.into()).collect();
    let len = keys.len();
    let mut keys_slice = keys.into_boxed_slice();
    let keys_ptr = keys_slice.as_mut_ptr();
    std::mem::forget(keys_slice);
    let mut values_slice = values.into_boxed_slice();
    let values_ptr = values_slice.as_mut_ptr();
    std::mem::forget(values_slice);
    Self { keys_ptr, values_ptr, len }
  }
}

impl <K1, K2, V1, V2> From<HashMap<K2, V2>> for CMap<K1, V1> 
  where
    K1: Free, K2: Into<K1> + Clone, V1: Free, V2: Into<V1> + Clone
{
  fn from(map: HashMap<K2, V2>) -> Self {
    let keys: Vec<K1> = map.keys().cloned().map(|k| k.into()).collect();
    let values: Vec<V1> = map.values().cloned().map(|v| v.into()).collect();
    let len = keys.len();
    let mut keys_slice = keys.into_boxed_slice();
    let keys_ptr = keys_slice.as_mut_ptr();
    std::mem::forget(keys_slice);
    let mut values_slice = values.into_boxed_slice();
    let values_ptr = values_slice.as_mut_ptr();
    std::mem::forget(values_slice);
    Self { keys_ptr, values_ptr, len }
  }
}
