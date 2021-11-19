use std::convert::{TryFrom, TryInto};

use cardano_serialization_lib::plutus::PlutusList as RPlutusList;

use crate::{
  array::CArray, error::CError, panic::Result, ptr::*, transaction_witness_set::PlutusData,
};

pub type PlutusList = CArray<PlutusData>;

impl TryFrom<PlutusList> for RPlutusList {
  type Error = CError;

  fn try_from(plutus_list: PlutusList) -> Result<Self> {
    let vec = unsafe { plutus_list.unowned()? };
    Ok(Self::new()).and_then(|mut plutus_list| {
      vec
        .iter()
        .map(|&plutus_data| {
          plutus_data
            .try_into()
            .map(|plutus_data| plutus_list.add(&plutus_data))
        })
        .collect::<Result<Vec<_>>>()
        .map(|_| plutus_list)
    })
  }
}

impl TryFrom<RPlutusList> for PlutusList {
  type Error = CError;

  fn try_from(plutus_list: RPlutusList) -> Result<Self> {
    (0..plutus_list.len())
      .map(|index| plutus_list.get(index).try_into())
      .collect::<Result<Vec<PlutusData>>>()
      .map(|plutus_list| plutus_list.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_plutus_list_free(plutus_list: &mut PlutusList) {
  plutus_list.free()
}
