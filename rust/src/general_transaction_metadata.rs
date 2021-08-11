use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::metadata_list::MetadataList;
use crate::metadata_map::MetadataMap;
use crate::panic::*;
use crate::ptr::*;
use crate::string::*;
use crate::transaction_metadatum_labels::TransactionMetadatumLabel;
use cardano_serialization_lib::{
  metadata::{
    decode_arbitrary_bytes_from_metadatum, decode_metadatum_to_json_str,
    encode_arbitrary_bytes_as_metadatum, encode_json_str_to_metadatum,
    GeneralTransactionMetadata as RGeneralTransactionMetadata,
    MetadataJsonSchema as RMetadataJsonSchema, TransactionMetadatum as RTransactionMetadatum,
    TransactionMetadatumKind,
  },
  utils::{from_bignum, to_bignum, Int},
};
use serde_json::from_str;
use serde_json::{Number as RJsonNumber, Value as RJsonValue};
use std::convert::{TryFrom, TryInto};

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

pub type JsonValueMapKeyValue = CKeyValue<CharPtr, JsonValue>;

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
          .map(|(key, value)| (key.into_cstr(), value.into()).into())
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

#[repr(C)]
#[derive(Copy, Clone)]
pub enum MetadataJsonSchema {
  NoConversions,
  BasicConversions,
  DetailedSchema,
}

impl From<MetadataJsonSchema> for RMetadataJsonSchema {
  fn from(metadata_json_schema: MetadataJsonSchema) -> Self {
    match metadata_json_schema {
      MetadataJsonSchema::NoConversions => Self::NoConversions,
      MetadataJsonSchema::BasicConversions => Self::BasicConversions,
      MetadataJsonSchema::DetailedSchema => Self::DetailedSchema,
    }
  }
}

impl From<RMetadataJsonSchema> for MetadataJsonSchema {
  fn from(metadata_json_schema: RMetadataJsonSchema) -> Self {
    match metadata_json_schema {
      RMetadataJsonSchema::NoConversions => Self::NoConversions,
      RMetadataJsonSchema::BasicConversions => Self::BasicConversions,
      RMetadataJsonSchema::DetailedSchema => Self::DetailedSchema,
    }
  }
}

#[repr(C)]
#[derive(Copy)]
pub enum TransactionMetadatum {
  MetadataMapKind(MetadataMap),
  MetadataListKind(MetadataList),
  IntKind(u64),
  BytesKind(CData),
  TextKind(CharPtr),
}

impl Free for TransactionMetadatum {
  unsafe fn free(&mut self) {
    match self {
      TransactionMetadatum::MetadataMapKind(metadata_map) => metadata_map.free(),
      TransactionMetadatum::MetadataListKind(metadata_list) => metadata_list.free(),
      TransactionMetadatum::BytesKind(bytes) => bytes.free(),
      TransactionMetadatum::TextKind(text) => text.free(),
      _ => return,
    }
  }
}

impl Clone for TransactionMetadatum {
  fn clone(&self) -> Self {
    match self {
      TransactionMetadatum::MetadataMapKind(metadata_map) => {
        Self::MetadataMapKind(metadata_map.clone())
      }
      TransactionMetadatum::MetadataListKind(metadata_list) => {
        Self::MetadataListKind(metadata_list.clone())
      }
      TransactionMetadatum::IntKind(int) => Self::IntKind(int.clone()),
      TransactionMetadatum::BytesKind(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self::BytesKind(bytes.into())
      }
      TransactionMetadatum::TextKind(text) => {
        let text = unsafe { text.unowned().expect("Bad char pointer") };
        Self::TextKind(text.into_cstr())
      }
    }
  }
}

impl TryFrom<TransactionMetadatum> for RTransactionMetadatum {
  type Error = CError;

  fn try_from(transaction_metadatum: TransactionMetadatum) -> Result<Self> {
    match transaction_metadatum {
      TransactionMetadatum::MetadataMapKind(metadata_map) => metadata_map
        .try_into()
        .map(|metadata_map| Self::new_map(&metadata_map)),
      TransactionMetadatum::MetadataListKind(metadata_list) => metadata_list
        .try_into()
        .map(|metadata_list| Self::new_list(&metadata_list)),
      TransactionMetadatum::IntKind(int) => Ok(Self::new_int(&Int::new(&to_bignum(int)))),
      TransactionMetadatum::BytesKind(bytes) => {
        let bytes = unsafe { bytes.unowned().expect("Bad bytes pointer") };
        Self::new_bytes(bytes.to_vec()).into_result()
      }
      TransactionMetadatum::TextKind(text) => {
        let text = unsafe { text.unowned().expect("Bad char pointer") };
        Self::new_text(text.to_string()).into_result()
      }
    }
  }
}

impl TryFrom<RTransactionMetadatum> for TransactionMetadatum {
  type Error = CError;

  fn try_from(transaction_metadatum: RTransactionMetadatum) -> Result<Self> {
    match transaction_metadatum.kind() {
      TransactionMetadatumKind::MetadataMap => transaction_metadatum
        .as_map()
        .into_result()
        .and_then(|metadata_map| metadata_map.try_into())
        .map(|metadata_map| Self::MetadataMapKind(metadata_map)),
      TransactionMetadatumKind::MetadataList => transaction_metadatum
        .as_list()
        .into_result()
        .and_then(|metadata_list| metadata_list.try_into())
        .map(|metadata_list| Self::MetadataListKind(metadata_list)),
      TransactionMetadatumKind::Int => transaction_metadatum.as_int().into_result().map(|int| {
        Self::IntKind(from_bignum(
          &int.as_positive().or(int.as_negative()).unwrap(),
        ))
      }),
      TransactionMetadatumKind::Bytes => transaction_metadatum
        .as_bytes()
        .into_result()
        .map(|bytes| Self::BytesKind(bytes.into())),
      TransactionMetadatumKind::Text => transaction_metadatum
        .as_text()
        .into_result()
        .map(|text| Self::TextKind(text.into_cstr())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_encode_arbitrary_bytes_as_metadatum(
  bytes: CData, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    bytes
      .unowned()
      .map(|bytes| encode_arbitrary_bytes_as_metadatum(bytes))
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_decode_arbitrary_bytes_from_metadatum(
  transaction_metadatum: TransactionMetadatum, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_metadatum
      .try_into()
      .and_then(|transaction_metadatum| {
        decode_arbitrary_bytes_from_metadatum(&transaction_metadatum).into_result()
      })
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_encode_json_str_to_metadatum(
  json: CharPtr, schema: MetadataJsonSchema, result: &mut TransactionMetadatum, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    json
      .unowned()
      .and_then(|json| encode_json_str_to_metadatum(json.to_string(), schema.into()).into_result())
      .and_then(|transaction_metadatum| transaction_metadatum.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_decode_metadatum_to_json_str(
  transaction_metadatum: TransactionMetadatum, schema: MetadataJsonSchema, result: &mut CharPtr,
  error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_metadatum
      .try_into()
      .and_then(|transaction_metadatum| {
        decode_metadatum_to_json_str(&transaction_metadatum, schema.into()).into_result()
      })
      .map(|bytes| bytes.into_cstr())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_clone(
  transaction_metadatum: TransactionMetadatum, result: &mut TransactionMetadatum,
  error: &mut CError,
) -> bool {
  handle_exception(|| transaction_metadatum.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadatum_free(
  transaction_metadatum: &mut TransactionMetadatum,
) {
  transaction_metadatum.free()
}

pub type GeneralTransactionMetadataKeyValue =
  CKeyValue<TransactionMetadatumLabel, TransactionMetadatum>;
pub type GeneralTransactionMetadata = CArray<GeneralTransactionMetadataKeyValue>;

impl TryFrom<GeneralTransactionMetadata> for RGeneralTransactionMetadata {
  type Error = CError;

  fn try_from(general_transaction_metadata: GeneralTransactionMetadata) -> Result<Self> {
    let map = unsafe { general_transaction_metadata.as_hash_map()? };
    let mut general_transaction_metadata = Self::new();
    for (tm_label, tm) in map {
      let transaction_metadatum = tm.try_into()?;
      general_transaction_metadata.insert(&to_bignum(tm_label), &transaction_metadatum);
    }
    Ok(general_transaction_metadata)
  }
}

impl TryFrom<RGeneralTransactionMetadata> for GeneralTransactionMetadata {
  type Error = CError;

  fn try_from(general_transaction_metadata: RGeneralTransactionMetadata) -> Result<Self> {
    Ok(general_transaction_metadata.keys()).and_then(|tm_labels| {
      (0..tm_labels.len())
        .map(|index| tm_labels.get(index))
        .map(|tm_label| {
          general_transaction_metadata
            .get(&tm_label)
            .ok_or("Cannot get TransactionMetadatum by TransactionMetadatumLabel".into())
            .and_then(|tm| tm.try_into())
            .map(|tm| (from_bignum(&tm_label), tm).into())
        })
        .collect::<Result<Vec<GeneralTransactionMetadataKeyValue>>>()
        .map(|general_transaction_metadata| general_transaction_metadata.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_general_transaction_metadata_free(
  general_transaction_metadata: &mut GeneralTransactionMetadata,
) {
  general_transaction_metadata.free()
}
