use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::int::CInt128;
use crate::linear_fee::Coin;
use crate::option::COption;
use crate::panic::*;
use crate::pool_registration::UnitInterval;
use crate::ptr::*;
use crate::transaction_body::Epoch;
use crate::transaction_builder::BigNum;
use cardano_serialization_lib::{
  crypto::Nonce as RNonce,
  plutus::{
    CostModel as RCostModel, Costmdls as RCostmdls, ExUnitPrices as RExUnitPrices,
    ExUnits as RExUnits, Language as RLanguage, LanguageKind,
  },
  utils::{from_bignum, to_bignum},
  ProtocolParamUpdate as RProtocolParamUpdate, ProtocolVersion as RProtocolVersion,
  ProtocolVersions as RProtocolVersions,
};
use std::convert::{TryFrom, TryInto};

pub type Rational = UnitInterval;

pub type NonceHash = [u8; 32];

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Nonce {
  hash: COption<NonceHash>,
}

impl TryFrom<Nonce> for RNonce {
  type Error = CError;

  fn try_from(nonce: Nonce) -> Result<Self> {
    let hash: Option<[u8; 32]> = nonce.hash.into();
    if let Some(hash) = hash {
      Self::new_from_hash(hash.to_vec()).into_result()
    } else {
      Ok(Self::new_identity())
    }
  }
}

impl From<RNonce> for Nonce {
  fn from(nonce: RNonce) -> Self {
    Self {
      hash: nonce.get_hash().map(|hash| hash.try_into().unwrap()).into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_nonce_new_from_hash(
  data: CData, result: &mut Nonce, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RNonce::new_from_hash(bytes.to_vec()).into_result())
      .map(|nonce| nonce.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_nonce_to_bytes(
  nonce: Nonce, bytes: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    nonce
      .try_into()
      .map(|nonce: RNonce| nonce.to_bytes().into())
  })
  .response(bytes, error)
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ProtocolVersion {
  major: u32,
  minor: u32,
}

impl Free for ProtocolVersion {
  unsafe fn free(&mut self) {}
}

impl From<ProtocolVersion> for RProtocolVersion {
  fn from(protocol_version: ProtocolVersion) -> Self {
    Self::new(protocol_version.major, protocol_version.minor)
  }
}

impl From<RProtocolVersion> for ProtocolVersion {
  fn from(protocol_version: RProtocolVersion) -> Self {
    Self {
      major: protocol_version.major(),
      minor: protocol_version.minor(),
    }
  }
}

pub type ProtocolVersions = CArray<ProtocolVersion>;

impl TryFrom<ProtocolVersions> for RProtocolVersions {
  type Error = CError;

  fn try_from(protocol_versions: ProtocolVersions) -> Result<Self> {
    let vec = unsafe { protocol_versions.unowned()? };
    let mut protocol_versions = Self::new();
    for protocol_version in vec.to_vec() {
      protocol_versions.add(&protocol_version.into())
    }
    Ok(protocol_versions)
  }
}

impl From<RProtocolVersions> for ProtocolVersions {
  fn from(protocol_versions: RProtocolVersions) -> Self {
    (0..protocol_versions.len())
      .map(|index| protocol_versions.get(index))
      .map(|protocol_version| protocol_version.into())
      .collect::<Vec<ProtocolVersion>>()
      .into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_versions_free(protocol_versions: &mut ProtocolVersions) {
  protocol_versions.free();
}

#[repr(C)]
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Language {
  PlutusV1,
}

impl Free for Language {
  unsafe fn free(&mut self) {}
}

impl From<Language> for RLanguage {
  fn from(language: Language) -> Self {
    match language {
      Language::PlutusV1 => Self::new_plutus_v1(),
    }
  }
}

impl From<RLanguage> for Language {
  fn from(language: RLanguage) -> Self {
    match language.kind() {
      LanguageKind::PlutusV1 => Self::PlutusV1,
    }
  }
}

const COST_MODEL_OP_COUNT: usize = 166;

pub type CostModel = CArray<CInt128>;

impl TryFrom<CostModel> for RCostModel {
  type Error = CError;

  fn try_from(cost_model: CostModel) -> Result<Self> {
    let vec = unsafe { cost_model.unowned()? };
    Ok(Self::new()).and_then(|mut cost_model| {
      vec
        .iter()
        .enumerate()
        .map(|(operation, &cost)| cost_model.set(operation, &cost.into()).into_result())
        .collect::<Result<Vec<_>>>()
        .map(|_| cost_model)
    })
  }
}

impl TryFrom<RCostModel> for CostModel {
  type Error = CError;

  fn try_from(cost_model: RCostModel) -> Result<Self> {
    (0..COST_MODEL_OP_COUNT)
      .map(|operation| {
        cost_model
          .get(operation)
          .map(|cost| cost.into())
          .into_result()
      })
      .collect::<Result<Vec<CInt128>>>()
      .map(|cost_model| cost_model.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_cost_model_free(cost_model: &mut CostModel) {
  cost_model.free();
}

pub type Costmdls = CArray<CKeyValue<Language, CostModel>>;

impl TryFrom<Costmdls> for RCostmdls {
  type Error = CError;

  fn try_from(costmdls: Costmdls) -> Result<Self> {
    let map = unsafe { costmdls.as_btree_map()? };
    Ok(Self::new()).and_then(|mut costmdls| {
      map
        .into_iter()
        .map(|(language, cost_model)| {
          cost_model
            .try_into()
            .map(|cost_model| costmdls.insert(&language.into(), &cost_model))
        })
        .collect::<Result<Vec<_>>>()
        .map(|_| costmdls)
    })
  }
}

impl TryFrom<RCostmdls> for Costmdls {
  type Error = CError;

  fn try_from(costmdls: RCostmdls) -> Result<Self> {
    Ok(costmdls.keys()).and_then(|languages| {
      (0..languages.len())
        .map(|index| languages.get(index))
        .map(|language| {
          costmdls
            .get(&language)
            .ok_or("Cannot get CostModel by Language".into())
            .and_then(|cost_model| cost_model.try_into())
            .map(|cost_model| (language.into(), cost_model).into())
        })
        .collect::<Result<Vec<CKeyValue<Language, CostModel>>>>()
        .map(|costmdls| costmdls.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_costmdls_free(costmdls: &mut Costmdls) {
  costmdls.free();
}

pub type SubCoin = UnitInterval;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ExUnitPrices {
  mem_price: SubCoin,
  step_price: SubCoin,
}

impl From<ExUnitPrices> for RExUnitPrices {
  fn from(ex_unit_prices: ExUnitPrices) -> Self {
    Self::new(
      &ex_unit_prices.mem_price.into(),
      &ex_unit_prices.step_price.into(),
    )
  }
}

impl From<RExUnitPrices> for ExUnitPrices {
  fn from(ex_unit_prices: RExUnitPrices) -> Self {
    Self {
      mem_price: ex_unit_prices.mem_price().into(),
      step_price: ex_unit_prices.step_price().into(),
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ExUnits {
  mem: BigNum,
  steps: BigNum,
}

impl From<ExUnits> for RExUnits {
  fn from(ex_units: ExUnits) -> Self {
    Self::new(&to_bignum(ex_units.mem), &to_bignum(ex_units.steps))
  }
}

impl From<RExUnits> for ExUnits {
  fn from(ex_units: RExUnits) -> Self {
    Self {
      mem: from_bignum(&ex_units.mem()),
      steps: from_bignum(&ex_units.steps()),
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ProtocolParamUpdate {
  minfee_a: COption<Coin>,
  minfee_b: COption<Coin>,
  max_block_body_size: COption<u32>,
  max_tx_size: COption<u32>,
  max_block_header_size: COption<u32>,
  key_deposit: COption<Coin>,
  pool_deposit: COption<Coin>,
  max_epoch: COption<Epoch>,
  n_opt: COption<u32>,
  pool_pledge_influence: COption<Rational>,
  expansion_rate: COption<UnitInterval>,
  treasury_growth_rate: COption<UnitInterval>,
  d: COption<UnitInterval>,
  extra_entropy: COption<Nonce>,
  protocol_version: COption<ProtocolVersions>,
  min_pool_cost: COption<Coin>,
  ada_per_utxo_byte: COption<Coin>,
  cost_models: COption<Costmdls>,
  execution_costs: COption<ExUnitPrices>,
  max_tx_ex_units: COption<ExUnits>,
  max_block_ex_units: COption<ExUnits>,
  max_value_size: COption<u32>,
}

impl Free for ProtocolParamUpdate {
  unsafe fn free(&mut self) {
    self.protocol_version.free()
  }
}

impl TryFrom<ProtocolParamUpdate> for RProtocolParamUpdate {
  type Error = CError;

  fn try_from(ppu: ProtocolParamUpdate) -> Result<Self> {
    let extra_entropy: Option<Nonce> = ppu.extra_entropy.into();
    extra_entropy
      .map(|ee| ee.try_into())
      .transpose()
      .zip({
        let protocol_version: Option<ProtocolVersions> = ppu.protocol_version.into();
        protocol_version.map(|pv| pv.try_into()).transpose()
      })
      .zip({
        let cost_models: Option<Costmdls> = ppu.cost_models.into();
        cost_models.map(|cm| cm.try_into()).transpose()
      })
      .map(|((extra_entropy, protocol_version), cost_models)| {
        let mut new_ppu = Self::new();
        let minfee_a: Option<Coin> = ppu.minfee_a.into();
        minfee_a.map(|minfee_a| new_ppu.set_minfee_a(&to_bignum(minfee_a)));
        let minfee_b: Option<Coin> = ppu.minfee_b.into();
        minfee_b.map(|minfee_b| new_ppu.set_minfee_b(&to_bignum(minfee_b)));
        let max_block_body_size: Option<u32> = ppu.max_block_body_size.into();
        max_block_body_size.map(|mbbs| new_ppu.set_max_block_body_size(mbbs));
        let max_tx_size: Option<u32> = ppu.max_tx_size.into();
        max_tx_size.map(|max_tx_size| new_ppu.set_max_tx_size(max_tx_size));
        let max_block_header_size: Option<u32> = ppu.max_block_header_size.into();
        max_block_header_size.map(|mbhs| new_ppu.set_max_block_header_size(mbhs));
        let key_deposit: Option<Coin> = ppu.key_deposit.into();
        key_deposit.map(|kd| new_ppu.set_key_deposit(&to_bignum(kd)));
        let pool_deposit: Option<Coin> = ppu.pool_deposit.into();
        pool_deposit.map(|pd| new_ppu.set_pool_deposit(&to_bignum(pd)));
        let max_epoch: Option<Epoch> = ppu.max_epoch.into();
        max_epoch.map(|max_epoch| new_ppu.set_max_epoch(max_epoch));
        let n_opt: Option<u32> = ppu.n_opt.into();
        n_opt.map(|n_opt| new_ppu.set_n_opt(n_opt));
        let pool_pledge_influence: Option<Rational> = ppu.pool_pledge_influence.into();
        pool_pledge_influence.map(|ppi| new_ppu.set_pool_pledge_influence(&ppi.into()));
        let expansion_rate: Option<UnitInterval> = ppu.expansion_rate.into();
        expansion_rate.map(|er| new_ppu.set_expansion_rate(&er.into()));
        let treasury_growth_rate: Option<UnitInterval> = ppu.treasury_growth_rate.into();
        treasury_growth_rate.map(|tgr| new_ppu.set_treasury_growth_rate(&tgr.into()));
        let d: Option<UnitInterval> = ppu.d.into();
        d.map(|d| new_ppu.set_d(&d.into()));
        extra_entropy.map(|extra_entropy| new_ppu.set_extra_entropy(&extra_entropy));
        protocol_version.map(|pv| new_ppu.set_protocol_version(&pv));
        let min_pool_cost: Option<Coin> = ppu.min_pool_cost.into();
        min_pool_cost.map(|mpc| new_ppu.set_min_pool_cost(&to_bignum(mpc)));
        let ada_per_utxo_byte: Option<Coin> = ppu.ada_per_utxo_byte.into();
        ada_per_utxo_byte.map(|apub| new_ppu.set_ada_per_utxo_byte(&to_bignum(apub)));
        cost_models.map(|cost_models| new_ppu.set_cost_models(&cost_models));
        let execution_costs: Option<ExUnitPrices> = ppu.execution_costs.into();
        execution_costs.map(|ec| new_ppu.set_execution_costs(&ec.into()));
        let max_tx_ex_units: Option<ExUnits> = ppu.max_tx_ex_units.into();
        max_tx_ex_units.map(|mteu| new_ppu.set_max_tx_ex_units(&mteu.into()));
        let max_block_ex_units: Option<ExUnits> = ppu.max_block_ex_units.into();
        max_block_ex_units.map(|mbeu| new_ppu.set_max_block_ex_units(&mbeu.into()));
        let max_value_size: Option<u32> = ppu.max_value_size.into();
        max_value_size.map(|mvs| new_ppu.set_max_value_size(mvs));
        new_ppu
      })
  }
}

impl TryFrom<RProtocolParamUpdate> for ProtocolParamUpdate {
  type Error = CError;

  fn try_from(ppu: RProtocolParamUpdate) -> Result<Self> {
    ppu
      .cost_models()
      .map(|costmdls| costmdls.try_into())
      .transpose()
      .map(|costmdls| Self {
        minfee_a: ppu.minfee_a().map(|minfee_a| from_bignum(&minfee_a)).into(),
        minfee_b: ppu.minfee_b().map(|minfee_b| from_bignum(&minfee_b)).into(),
        max_block_body_size: ppu.max_block_body_size().into(),
        max_tx_size: ppu.max_tx_size().into(),
        max_block_header_size: ppu.max_block_header_size().into(),
        key_deposit: ppu.key_deposit().map(|kd| from_bignum(&kd)).into(),
        pool_deposit: ppu.pool_deposit().map(|pd| from_bignum(&pd)).into(),
        max_epoch: ppu.max_epoch().into(),
        n_opt: ppu.n_opt().into(),
        pool_pledge_influence: ppu.pool_pledge_influence().map(|ppi| ppi.into()).into(),
        expansion_rate: ppu.expansion_rate().map(|er| er.into()).into(),
        treasury_growth_rate: ppu.treasury_growth_rate().map(|tgr| tgr.into()).into(),
        d: ppu.d().map(|d| d.into()).into(),
        extra_entropy: ppu.extra_entropy().map(|ee| ee.into()).into(),
        protocol_version: ppu.protocol_version().map(|pv| pv.into()).into(),
        min_pool_cost: ppu.min_pool_cost().map(|mpc| from_bignum(&mpc)).into(),
        ada_per_utxo_byte: ppu
          .ada_per_utxo_byte()
          .map(|apub| from_bignum(&apub))
          .into(),
        cost_models: costmdls.into(),
        execution_costs: ppu.execution_costs().map(|ec| ec.into()).into(),
        max_tx_ex_units: ppu.max_tx_ex_units().map(|mteu| mteu.into()).into(),
        max_block_ex_units: ppu.max_block_ex_units().map(|mbeu| mbeu.into()).into(),
        max_value_size: ppu.max_value_size().into(),
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_from_bytes(
  data: CData, result: &mut ProtocolParamUpdate, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RProtocolParamUpdate::from_bytes(bytes.to_vec()).into_result())
      .and_then(|protocol_param_update| protocol_param_update.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_to_bytes(
  protocol_param_update: ProtocolParamUpdate, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    protocol_param_update
      .try_into()
      .map(|protocol_param_update: RProtocolParamUpdate| protocol_param_update.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_clone(
  protocol_param_update: ProtocolParamUpdate, result: &mut ProtocolParamUpdate, error: &mut CError,
) -> bool {
  handle_exception(|| protocol_param_update.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_protocol_param_update_free(
  protocol_param_update: &mut ProtocolParamUpdate,
) {
  protocol_param_update.free()
}
