use crate::array::CArray;
use crate::constr_plutus_data::ConstrPlutusData;
use crate::data::CData;
use crate::error::CError;
use crate::int::CBigInt;
use crate::option::COption;
use crate::panic::*;
use crate::plutus_list::PlutusList;
use crate::plutus_map::PlutusMap;
use crate::protocol_param_update::ExUnits;
use crate::ptr::*;
use crate::transaction_builder::BigNum;
use crate::transaction_metadata::NativeScripts;
use crate::vkeywitness::Vkeywitnesses;
use crate::{bootstrap_witness::BootstrapWitnesses, transaction_metadata::PlutusScripts};
use cardano_serialization_lib::{
  plutus::{
    PlutusData as RPlutusData, PlutusDataKind, Redeemer as RRedeemer, RedeemerTag as RRedeemerTag,
    RedeemerTagKind, Redeemers as RRedeemers,
  },
  utils::{from_bignum, to_bignum, BigInt as RBigInt},
  TransactionWitnessSet as RTransactionWitnessSet,
};
use num_bigint::BigInt;
use std::convert::{TryFrom, TryInto};

// for transmute
struct TBigInt(BigInt);

impl TryFrom<CBigInt> for RBigInt {
  type Error = CError;

  fn try_from(big_int: CBigInt) -> Result<Self> {
    big_int
      .try_into()
      .map(|big_int| unsafe { std::mem::transmute(TBigInt(big_int)) })
  }
}

impl From<RBigInt> for CBigInt {
  fn from(big_int: RBigInt) -> Self {
    let big_int: TBigInt = unsafe { std::mem::transmute(big_int) };
    big_int.0.into()
  }
}

#[repr(C)]
#[derive(Copy)]
pub enum PlutusData {
  ConstrPlutusDataKind(ConstrPlutusData),
  MapKind(PlutusMap),
  ListKind(PlutusList),
  IntegerKind(CBigInt),
  PlutusBytesKind(CData),
}

impl Free for PlutusData {
  unsafe fn free(&mut self) {
    match self {
      PlutusData::ConstrPlutusDataKind(constr_plutus_data) => constr_plutus_data.free(),
      PlutusData::MapKind(map) => map.free(),
      PlutusData::ListKind(list) => list.free(),
      PlutusData::IntegerKind(integer) => integer.free(),
      PlutusData::PlutusBytesKind(bytes) => bytes.free(),
    }
  }
}

impl Clone for PlutusData {
  fn clone(&self) -> Self {
    match self {
      Self::ConstrPlutusDataKind(constr_plutus_data) => {
        Self::ConstrPlutusDataKind(constr_plutus_data.clone())
      }
      Self::MapKind(map) => Self::MapKind(map.clone()),
      Self::ListKind(list) => Self::ListKind(list.clone()),
      Self::IntegerKind(integer) => Self::IntegerKind(integer.clone()),
      Self::PlutusBytesKind(bytes) => {
        Self::PlutusBytesKind(unsafe { bytes.unowned().expect("Bad bytes pointer").into() })
      }
    }
  }
}

impl TryFrom<PlutusData> for RPlutusData {
  type Error = CError;

  fn try_from(plutus_data: PlutusData) -> Result<Self> {
    match plutus_data {
      PlutusData::ConstrPlutusDataKind(constr_plutus_data) => constr_plutus_data
        .try_into()
        .map(|constr_plutus_data| Self::new_constr_plutus_data(&constr_plutus_data)),
      PlutusData::MapKind(map) => map.try_into().map(|map| Self::new_map(&map)),
      PlutusData::ListKind(list) => list.try_into().map(|list| Self::new_list(&list)),
      PlutusData::IntegerKind(integer) => integer
        .try_into()
        .map(|integer| Self::new_integer(&integer)),
      PlutusData::PlutusBytesKind(bytes) => unsafe {
        bytes.unowned().map(|bytes| Self::new_bytes(bytes.to_vec()))
      },
    }
  }
}

impl TryFrom<RPlutusData> for PlutusData {
  type Error = CError;

  fn try_from(plutus_data: RPlutusData) -> Result<Self> {
    match plutus_data.kind() {
      PlutusDataKind::ConstrPlutusData => plutus_data
        .as_constr_plutus_data()
        .ok_or("Empty ConstrPlutusData".into())
        .and_then(|constr_plutus_data| constr_plutus_data.try_into())
        .map(|constr_plutus_data| Self::ConstrPlutusDataKind(constr_plutus_data)),
      PlutusDataKind::Map => plutus_data
        .as_map()
        .ok_or("Empty Map".into())
        .and_then(|map| map.try_into())
        .map(|map| Self::MapKind(map)),
      PlutusDataKind::List => plutus_data
        .as_list()
        .ok_or("Empty List".into())
        .and_then(|list| list.try_into())
        .map(|list| Self::ListKind(list)),
      PlutusDataKind::Integer => plutus_data
        .as_integer()
        .ok_or("Empty Integer".into())
        .map(|integer| Self::IntegerKind(integer.into())),
      PlutusDataKind::Bytes => plutus_data
        .as_bytes()
        .ok_or("Empty Bytes".into())
        .map(|bytes| Self::PlutusBytesKind(bytes.into())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_plutus_data_clone(
  plutus_data: PlutusData, result: &mut PlutusData, error: &mut CError,
) -> bool {
  handle_exception(|| plutus_data.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_plutus_data_free(plutus_data: &mut PlutusData) {
  plutus_data.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum RedeemerTag {
  SpendKind,
  MintKind,
  CertKind,
  RewardKind,
}

impl From<RedeemerTag> for RRedeemerTag {
  fn from(redeemer_tag: RedeemerTag) -> Self {
    match redeemer_tag {
      RedeemerTag::SpendKind => Self::new_spend(),
      RedeemerTag::MintKind => Self::new_mint(),
      RedeemerTag::CertKind => Self::new_cert(),
      RedeemerTag::RewardKind => Self::new_reward(),
    }
  }
}

impl From<RRedeemerTag> for RedeemerTag {
  fn from(redeemer_tag: RRedeemerTag) -> Self {
    match redeemer_tag.kind() {
      RedeemerTagKind::Spend => Self::SpendKind,
      RedeemerTagKind::Mint => Self::MintKind,
      RedeemerTagKind::Cert => Self::CertKind,
      RedeemerTagKind::Reward => Self::RewardKind,
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Redeemer {
  tag: RedeemerTag,
  index: BigNum,
  data: PlutusData,
  ex_units: ExUnits,
}

impl Free for Redeemer {
  unsafe fn free(&mut self) {
    self.data.free()
  }
}

impl TryFrom<Redeemer> for RRedeemer {
  type Error = CError;

  fn try_from(redeemer: Redeemer) -> Result<Self> {
    redeemer.data.try_into().map(|data| {
      Self::new(
        &redeemer.tag.into(),
        &to_bignum(redeemer.index),
        &data,
        &redeemer.ex_units.into(),
      )
    })
  }
}

impl TryFrom<RRedeemer> for Redeemer {
  type Error = CError;

  fn try_from(redeemer: RRedeemer) -> Result<Self> {
    redeemer.data().try_into().map(|data| Self {
      tag: redeemer.tag().into(),
      index: from_bignum(&redeemer.index()),
      data,
      ex_units: redeemer.ex_units().into(),
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_redeemer_clone(
  redeemer: Redeemer, result: &mut Redeemer, error: &mut CError,
) -> bool {
  handle_exception(|| redeemer.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_redeemer_free(redeemer: &mut Redeemer) {
  redeemer.free()
}

pub type Redeemers = CArray<Redeemer>;

impl TryFrom<Redeemers> for RRedeemers {
  type Error = CError;

  fn try_from(redeemers: Redeemers) -> Result<Self> {
    let vec = unsafe { redeemers.unowned()? };
    Ok(Self::new()).and_then(|mut redeemers| {
      vec
        .iter()
        .map(|&redeemer| redeemer.try_into().map(|redeemer| redeemers.add(&redeemer)))
        .collect::<Result<Vec<_>>>()
        .map(|_| redeemers)
    })
  }
}

impl TryFrom<RRedeemers> for Redeemers {
  type Error = CError;

  fn try_from(redeemers: RRedeemers) -> Result<Self> {
    (0..redeemers.len())
      .map(|index| redeemers.get(index).try_into())
      .collect::<Result<Vec<Redeemer>>>()
      .map(|redeemers| redeemers.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_redeemers_free(redeemers: &mut Redeemers) {
  redeemers.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionWitnessSet {
  vkeys: COption<Vkeywitnesses>,
  native_scripts: COption<NativeScripts>,
  bootstraps: COption<BootstrapWitnesses>,
  plutus_scripts: COption<PlutusScripts>,
  plutus_data: COption<PlutusList>,
  redeemers: COption<Redeemers>,
}

impl Free for TransactionWitnessSet {
  unsafe fn free(&mut self) {
    self.vkeys.free();
    self.native_scripts.free();
    self.bootstraps.free();
    self.plutus_scripts.free();
    self.plutus_data.free();
    self.redeemers.free();
  }
}

impl TryFrom<RTransactionWitnessSet> for TransactionWitnessSet {
  type Error = CError;

  fn try_from(transaction_witness_set: RTransactionWitnessSet) -> Result<Self> {
    transaction_witness_set
      .native_scripts()
      .map(|native_scripts| native_scripts.try_into())
      .transpose()
      .zip(
        transaction_witness_set
          .plutus_data()
          .map(|plutus_data| plutus_data.try_into())
          .transpose(),
      )
      .zip(
        transaction_witness_set
          .redeemers()
          .map(|redeemers| redeemers.try_into())
          .transpose(),
      )
      .map(|((native_scripts, plutus_data), redeemers)| Self {
        vkeys: transaction_witness_set
          .vkeys()
          .map(|vkeywitnesses| vkeywitnesses.into())
          .into(),
        native_scripts: native_scripts.into(),
        bootstraps: transaction_witness_set
          .bootstraps()
          .map(|bootstrap_witnesses| bootstrap_witnesses.into())
          .into(),
        plutus_scripts: transaction_witness_set
          .plutus_scripts()
          .map(|plutus_scripts| plutus_scripts.into())
          .into(),
        plutus_data: plutus_data.into(),
        redeemers: redeemers.into(),
      })
  }
}

impl TryFrom<TransactionWitnessSet> for RTransactionWitnessSet {
  type Error = CError;

  fn try_from(transaction_witness_set: TransactionWitnessSet) -> Result<Self> {
    let vkeys: Option<Vkeywitnesses> = transaction_witness_set.vkeys.into();
    let native_scripts: Option<NativeScripts> = transaction_witness_set.native_scripts.into();
    let bootstraps: Option<BootstrapWitnesses> = transaction_witness_set.bootstraps.into();
    let plutus_scripts: Option<PlutusScripts> = transaction_witness_set.plutus_scripts.into();
    let plutus_data: Option<PlutusList> = transaction_witness_set.plutus_data.into();
    let redeemers: Option<Redeemers> = transaction_witness_set.redeemers.into();
    let mut transaction_witness_set = RTransactionWitnessSet::new();
    if let Some(vkeys) = vkeys {
      let vkeys = vkeys.try_into()?;
      transaction_witness_set.set_vkeys(&vkeys);
    }
    if let Some(native_scripts) = native_scripts {
      let native_scripts = native_scripts.try_into()?;
      transaction_witness_set.set_native_scripts(&native_scripts);
    }
    if let Some(bootstraps) = bootstraps {
      let bootstraps = bootstraps.try_into()?;
      transaction_witness_set.set_bootstraps(&bootstraps);
    }
    if let Some(plutus_scripts) = plutus_scripts {
      let plutus_scripts = plutus_scripts.try_into()?;
      transaction_witness_set.set_plutus_scripts(&plutus_scripts);
    }
    if let Some(plutus_data) = plutus_data {
      let plutus_data = plutus_data.try_into()?;
      transaction_witness_set.set_plutus_data(&plutus_data);
    }
    if let Some(redeemers) = redeemers {
      let redeemers = redeemers.try_into()?;
      transaction_witness_set.set_redeemers(&redeemers);
    }
    Ok(transaction_witness_set)
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_witness_set_clone(
  transaction_witness_set: TransactionWitnessSet, result: &mut TransactionWitnessSet,
  error: &mut CError,
) -> bool {
  handle_exception(|| transaction_witness_set.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_witness_set_free(
  transaction_witness_set: &mut TransactionWitnessSet,
) {
  transaction_witness_set.free();
}
