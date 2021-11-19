use std::convert::{TryFrom, TryInto};

use cardano_serialization_lib::{
  plutus::ConstrPlutusData as RConstrPlutusData,
  utils::{from_bignum, to_bignum},
};

use crate::{
  error::CError, panic::*, plutus_list::PlutusList, ptr::*, transaction_builder::BigNum,
};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ConstrPlutusData {
  alternative: BigNum,
  data: PlutusList,
}

impl Free for ConstrPlutusData {
  unsafe fn free(&mut self) {
    self.data.free()
  }
}

impl TryFrom<ConstrPlutusData> for RConstrPlutusData {
  type Error = CError;

  fn try_from(constr_plutus_data: ConstrPlutusData) -> Result<Self> {
    constr_plutus_data
      .data
      .try_into()
      .map(|data| Self::new(&to_bignum(constr_plutus_data.alternative), &data))
  }
}

impl TryFrom<RConstrPlutusData> for ConstrPlutusData {
  type Error = CError;

  fn try_from(constr_plutus_data: RConstrPlutusData) -> Result<Self> {
    constr_plutus_data.data().try_into().map(|data| Self {
      alternative: from_bignum(&constr_plutus_data.alternative()),
      data,
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_constr_plutus_data_clone(
  constr_plutus_data: ConstrPlutusData, result: &mut ConstrPlutusData, error: &mut CError,
) -> bool {
  handle_exception(|| constr_plutus_data.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_constr_plutus_data_free(
  constr_plutus_data: &mut ConstrPlutusData,
) {
  constr_plutus_data.free()
}
