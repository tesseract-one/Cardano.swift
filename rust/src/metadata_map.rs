use crate::array::*;
use crate::error::CError;
use crate::general_transaction_metadata::TransactionMetadatum;
use crate::panic::*;
use crate::pointer::CPointer;
use crate::ptr::*;
use cardano_serialization_lib::metadata::MetadataMap as RMetadataMap;
use std::convert::{TryFrom, TryInto};

pub type MetadataMapKeyValue =
  CKeyValue<CPointer<TransactionMetadatum>, CPointer<TransactionMetadatum>>;
pub type MetadataMap = CArray<MetadataMapKeyValue>;

impl TryFrom<MetadataMap> for RMetadataMap {
  type Error = CError;

  fn try_from(metadata_map: MetadataMap) -> Result<Self> {
    let vec = unsafe { metadata_map.unowned()? };
    let mut metadata_map = RMetadataMap::new();
    for ckv in vec.to_vec() {
      let (tm_key, tm_value) = ckv.into();
      let tm_key = unsafe { (*tm_key.unowned()?).try_into()? };
      let tm_value = unsafe { (*tm_value.unowned()?).try_into()? };
      metadata_map.insert(&tm_key, &tm_value);
    }
    Ok(metadata_map)
  }
}

impl TryFrom<RMetadataMap> for MetadataMap {
  type Error = CError;

  fn try_from(metadata_map: RMetadataMap) -> Result<Self> {
    Ok(metadata_map.keys()).and_then(|keys| {
      (0..keys.len())
        .map(|index| keys.get(index))
        .map(|tm_key| {
          metadata_map
            .get(&tm_key)
            .into_result()
            .and_then(|tm_value| tm_value.try_into())
            .zip(tm_key.try_into())
            .map(|(tm_value, tm_key)| (CPointer::new(&tm_key), CPointer::new(&tm_value)).into())
        })
        .collect::<Result<Vec<MetadataMapKeyValue>>>()
        .map(|metadata_map| metadata_map.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_metadata_map_free(metadata_map: &mut MetadataMap) {
  metadata_map.free();
}
