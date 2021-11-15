use crate::error::CError;
use crate::linear_fee::Coin;
use crate::option::COption;
use crate::panic::*;
use crate::pool_registration::UnitInterval;
use crate::ptr::*;
use crate::transaction_body::Epoch;
use crate::{array::CArray, data::CData};
use cardano_serialization_lib::utils::{from_bignum, to_bignum};
use cardano_serialization_lib::{
  crypto::Nonce as RNonce, ProtocolParamUpdate as RProtocolParamUpdate,
  ProtocolVersion as RProtocolVersion, ProtocolVersions as RProtocolVersions,
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
  min_utxo_value: COption<Coin>,
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
      .map(|(extra_entropy, protocol_version)| {
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
        let min_utxo_value: Option<Coin> = ppu.min_utxo_value.into();
        todo!();
        // min_utxo_value.map(|muv| new_ppu.set_min_utxo_value(&to_bignum(muv)));
        // new_ppu
      })
  }
}

impl From<RProtocolParamUpdate> for ProtocolParamUpdate {
  fn from(ppu: RProtocolParamUpdate) -> Self {
    todo!();
    // Self {
    //   minfee_a: ppu.minfee_a().map(|minfee_a| from_bignum(&minfee_a)).into(),
    //   minfee_b: ppu.minfee_b().map(|minfee_b| from_bignum(&minfee_b)).into(),
    //   max_block_body_size: ppu.max_block_body_size().into(),
    //   max_tx_size: ppu.max_tx_size().into(),
    //   max_block_header_size: ppu.max_block_header_size().into(),
    //   key_deposit: ppu.key_deposit().map(|kd| from_bignum(&kd)).into(),
    //   pool_deposit: ppu.pool_deposit().map(|pd| from_bignum(&pd)).into(),
    //   max_epoch: ppu.max_epoch().into(),
    //   n_opt: ppu.n_opt().into(),
    //   pool_pledge_influence: ppu.pool_pledge_influence().map(|ppi| ppi.into()).into(),
    //   expansion_rate: ppu.expansion_rate().map(|er| er.into()).into(),
    //   treasury_growth_rate: ppu.treasury_growth_rate().map(|tgr| tgr.into()).into(),
    //   d: ppu.d().map(|d| d.into()).into(),
    //   extra_entropy: ppu.extra_entropy().map(|ee| ee.into()).into(),
    //   protocol_version: ppu.protocol_version().map(|pv| pv.into()).into(),
    //   min_utxo_value: ppu.min_utxo_value().map(|muv| from_bignum(&muv)).into(),
    // }
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
      .map(|protocol_param_update| protocol_param_update.into())
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
