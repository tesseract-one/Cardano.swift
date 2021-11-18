use crate::array::*;
use crate::asset_name::AssetName;
use crate::certificate::Certificates;
use crate::data::CData;
use crate::error::CError;
use crate::genesis_key_delegation::GenesisHash;
use crate::int::CInt128;
use crate::linear_fee::Coin;
use crate::multi_asset::PolicyID;
use crate::option::COption;
use crate::panic::*;
use crate::protocol_param_update::ProtocolParamUpdate;
use crate::ptr::*;
use crate::transaction_input::TransactionInputs;
use crate::transaction_output::TransactionOutputs;
use crate::withdrawals::Withdrawals;
use crate::{address::pointer::Slot, stake_credential::Ed25519KeyHashes};
use cardano_serialization_lib::{
  crypto::{AuxiliaryDataHash as RAuxiliaryDataHash, ScriptDataHash as RScriptDataHash},
  utils::{from_bignum, to_bignum},
  Mint as RMint, MintAssets as RMintAssets, NetworkId as RNetworkId, NetworkIdKind,
  ProposedProtocolParameterUpdates as RProposedProtocolParameterUpdates,
  TransactionBody as RTransactionBody, Update as RUpdate,
};
use std::convert::{TryFrom, TryInto};

pub type Epoch = u32;

pub type ProposedProtocolParameterUpdatesKeyValue = CKeyValue<GenesisHash, ProtocolParamUpdate>;
pub type ProposedProtocolParameterUpdates = CArray<ProposedProtocolParameterUpdatesKeyValue>;

impl Free for GenesisHash {
  unsafe fn free(&mut self) {}
}

impl TryFrom<ProposedProtocolParameterUpdates> for RProposedProtocolParameterUpdates {
  type Error = CError;

  fn try_from(pppu: ProposedProtocolParameterUpdates) -> Result<Self> {
    let map = unsafe { pppu.as_hash_map()? };
    let mut pppu = RProposedProtocolParameterUpdates::new();
    for (genesis_hash, protocol_param_update) in map {
      let protocol_param_update = protocol_param_update.try_into()?;
      pppu.insert(&genesis_hash.into(), &protocol_param_update);
    }
    Ok(pppu)
  }
}

impl TryFrom<RProposedProtocolParameterUpdates> for ProposedProtocolParameterUpdates {
  type Error = CError;

  fn try_from(pppu: RProposedProtocolParameterUpdates) -> Result<Self> {
    Ok(pppu.keys()).and_then(|genesis_hashes| {
      (0..genesis_hashes.len())
        .map(|index| genesis_hashes.get(index))
        .map(|genesis_hash| {
          pppu
            .get(&genesis_hash)
            .ok_or("Cannot get ProtocolParamUpdate by GenesisHash".into())
            .and_then(|ppu| ppu.try_into())
            .zip(genesis_hash.try_into())
            .map(|(ppu, genesis_hash)| (genesis_hash, ppu).into())
        })
        .collect::<Result<Vec<ProposedProtocolParameterUpdatesKeyValue>>>()
        .map(|pppu| pppu.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_proposed_protocol_parameter_updates_free(
  pppu: &mut ProposedProtocolParameterUpdates,
) {
  pppu.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Update {
  proposed_protocol_parameter_updates: ProposedProtocolParameterUpdates,
  epoch: Epoch,
}

impl Free for Update {
  unsafe fn free(&mut self) {
    self.proposed_protocol_parameter_updates.free()
  }
}

impl TryFrom<Update> for RUpdate {
  type Error = CError;

  fn try_from(update: Update) -> Result<Self> {
    update
      .proposed_protocol_parameter_updates
      .try_into()
      .map(|pppu| Self::new(&pppu, update.epoch))
  }
}

impl TryFrom<RUpdate> for Update {
  type Error = CError;

  fn try_from(update: RUpdate) -> Result<Self> {
    update.proposed_protocol_parameter_updates().try_into().map(
      |proposed_protocol_parameter_updates| Self {
        proposed_protocol_parameter_updates,
        epoch: update.epoch(),
      },
    )
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_update_clone(
  update: Update, result: &mut Update, error: &mut CError,
) -> bool {
  handle_exception(|| update.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_update_free(update: &mut Update) {
  update.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct AuxiliaryDataHash([u8; 32]);

impl From<RAuxiliaryDataHash> for AuxiliaryDataHash {
  fn from(hash: RAuxiliaryDataHash) -> Self {
    Self(hash.to_bytes().try_into().unwrap())
  }
}

impl From<AuxiliaryDataHash> for RAuxiliaryDataHash {
  fn from(hash: AuxiliaryDataHash) -> Self {
    hash.0.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_auxiliary_data_hash_to_bytes(
  auxiliary_data_hash: AuxiliaryDataHash, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let auxiliary_data_hash: RAuxiliaryDataHash = auxiliary_data_hash.into();
    auxiliary_data_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_auxiliary_data_hash_from_bytes(
  data: CData, result: &mut AuxiliaryDataHash, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RAuxiliaryDataHash::from_bytes(bytes.to_vec()).into_result())
      .map(|auxiliary_data_hash| auxiliary_data_hash.into())
  })
  .response(result, error)
}

pub type MintAssetsKeyValue = CKeyValue<AssetName, CInt128>;
pub type MintAssets = CArray<MintAssetsKeyValue>;

impl TryFrom<MintAssets> for RMintAssets {
  type Error = CError;

  fn try_from(mint_assets: MintAssets) -> Result<Self> {
    let map = unsafe { mint_assets.as_btree_map()? };
    let mut mint_assets = RMintAssets::new();
    for (asset_name, int) in map {
      let asset_name = asset_name.try_into()?;
      mint_assets.insert(&asset_name, int.into());
    }
    Ok(mint_assets)
  }
}

impl TryFrom<RMintAssets> for MintAssets {
  type Error = CError;

  fn try_from(mint_assets: RMintAssets) -> Result<Self> {
    Ok(mint_assets.keys()).and_then(|asset_names| {
      (0..asset_names.len())
        .map(|index| asset_names.get(index))
        .map(|asset_name| {
          mint_assets
            .get(&asset_name)
            .ok_or("Cannot get Int by AssetName".into())
            .zip(asset_name.try_into())
            .map(|(int, asset_name)| (asset_name, int.into()).into())
        })
        .collect::<Result<Vec<MintAssetsKeyValue>>>()
        .map(|mint_assets| mint_assets.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mint_assets_free(mint_assets: &mut MintAssets) {
  mint_assets.free()
}

pub type MintKeyValue = CKeyValue<PolicyID, MintAssets>;
pub type Mint = CArray<MintKeyValue>;

impl TryFrom<Mint> for RMint {
  type Error = CError;

  fn try_from(mint: Mint) -> Result<Self> {
    let map = unsafe { mint.as_btree_map()? };
    let mut mint = RMint::new();
    for (policy_id, mint_assets) in map {
      let mint_assets = mint_assets.try_into()?;
      mint.insert(&policy_id.into(), &mint_assets);
    }
    Ok(mint)
  }
}

impl TryFrom<RMint> for Mint {
  type Error = CError;

  fn try_from(mint: RMint) -> Result<Self> {
    Ok(mint.keys()).and_then(|policy_ids| {
      (0..policy_ids.len())
        .map(|index| policy_ids.get(index))
        .map(|policy_id| {
          mint
            .get(&policy_id)
            .ok_or("Cannot get MintAssets by PolicyID".into())
            .and_then(|mint_assets| mint_assets.try_into())
            .zip(policy_id.try_into())
            .map(|(mint_assets, policy_id)| (policy_id, mint_assets).into())
        })
        .collect::<Result<Vec<MintKeyValue>>>()
        .map(|mint| mint.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mint_free(mint: &mut Mint) {
  mint.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptDataHash([u8; 32]);

impl From<RScriptDataHash> for ScriptDataHash {
  fn from(hash: RScriptDataHash) -> Self {
    Self(hash.to_bytes().try_into().unwrap())
  }
}

impl From<ScriptDataHash> for RScriptDataHash {
  fn from(hash: ScriptDataHash) -> Self {
    hash.0.into()
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_data_hash_to_bytes(
  script_data_hash: ScriptDataHash, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception(|| {
    let script_data_hash: RScriptDataHash = script_data_hash.into();
    script_data_hash.to_bytes().into()
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_data_hash_from_bytes(
  data: CData, result: &mut ScriptDataHash, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RScriptDataHash::from_bytes(bytes.to_vec()).into_result())
      .map(|script_data_hash| script_data_hash.into())
  })
  .response(result, error)
}

pub type RequiredSigners = Ed25519KeyHashes;

#[repr(C)]
#[derive(Copy, Clone)]
pub enum NetworkId {
  Testnet,
  Mainnet,
}

impl From<NetworkId> for RNetworkId {
  fn from(network_id: NetworkId) -> Self {
    match network_id {
      NetworkId::Testnet => Self::testnet(),
      NetworkId::Mainnet => Self::mainnet(),
    }
  }
}

impl From<RNetworkId> for NetworkId {
  fn from(network_id: RNetworkId) -> Self {
    match network_id.kind() {
      NetworkIdKind::Testnet => Self::Testnet,
      NetworkIdKind::Mainnet => Self::Mainnet,
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionBody {
  inputs: TransactionInputs,
  outputs: TransactionOutputs,
  fee: Coin,
  ttl: COption<Slot>,
  certs: COption<Certificates>,
  withdrawals: COption<Withdrawals>,
  update: COption<Update>,
  auxiliary_data_hash: COption<AuxiliaryDataHash>,
  validity_start_interval: COption<Slot>,
  mint: COption<Mint>,
  script_data_hash: COption<ScriptDataHash>,
  collateral: COption<TransactionInputs>,
  required_signers: COption<RequiredSigners>,
  network_id: COption<NetworkId>,
}

impl Free for TransactionBody {
  unsafe fn free(&mut self) {
    self.inputs.free();
    self.outputs.free();
    self.certs.free();
    self.withdrawals.free();
    self.update.free();
    self.mint.free();
    self.collateral.free();
    self.required_signers.free();
  }
}

impl TryFrom<TransactionBody> for RTransactionBody {
  type Error = CError;

  fn try_from(tb: TransactionBody) -> Result<Self> {
    tb.inputs
      .try_into()
      .zip(tb.outputs.try_into())
      .map(|(inputs, outputs)| Self::new(&inputs, &outputs, &to_bignum(tb.fee), tb.ttl.into()))
      .zip({
        let certs: Option<Certificates> = tb.certs.into();
        certs.map(|certs| certs.try_into()).transpose()
      })
      .zip({
        let wls: Option<Withdrawals> = tb.withdrawals.into();
        wls.map(|wls| wls.try_into()).transpose()
      })
      .zip({
        let update: Option<Update> = tb.update.into();
        update.map(|update| update.try_into()).transpose()
      })
      .zip({
        let mint: Option<Mint> = tb.mint.into();
        mint.map(|mint| mint.try_into()).transpose()
      })
      .zip({
        let collateral: Option<TransactionInputs> = tb.collateral.into();
        collateral
          .map(|collateral| collateral.try_into())
          .transpose()
      })
      .zip({
        let required_signers: Option<RequiredSigners> = tb.required_signers.into();
        required_signers
          .map(|required_signers| required_signers.try_into())
          .transpose()
      })
      .map(
        |((((((mut new_tb, certs), wls), update), mint), collateral), required_signers)| {
          let adh: Option<AuxiliaryDataHash> = tb.auxiliary_data_hash.into();
          let vsi: Option<Slot> = tb.validity_start_interval.into();
          let sdh: Option<ScriptDataHash> = tb.script_data_hash.into();
          let network_id: Option<NetworkId> = tb.network_id.into();
          certs.map(|certs| new_tb.set_certs(&certs));
          wls.map(|wls| new_tb.set_withdrawals(&wls));
          update.map(|update| new_tb.set_update(&update));
          adh.map(|adh| new_tb.set_auxiliary_data_hash(&adh.into()));
          vsi.map(|vsi| new_tb.set_validity_start_interval(vsi));
          mint.map(|mint| new_tb.set_mint(&mint));
          sdh.map(|sdh| new_tb.set_script_data_hash(&sdh.into()));
          collateral.map(|collateral| new_tb.set_collateral(&collateral));
          required_signers.map(|required_signers| new_tb.set_required_signers(&required_signers));
          network_id.map(|network_id| new_tb.set_network_id(&network_id.into()));
          new_tb
        },
      )
  }
}

impl TryFrom<RTransactionBody> for TransactionBody {
  type Error = CError;

  fn try_from(tb: RTransactionBody) -> Result<Self> {
    tb.inputs()
      .try_into()
      .zip(tb.outputs().try_into())
      .zip(tb.certs().map(|certs| certs.try_into()).transpose())
      .zip(tb.withdrawals().map(|wls| wls.try_into()).transpose())
      .zip(tb.update().map(|update| update.try_into()).transpose())
      .zip(tb.multiassets().map(|mint| mint.try_into()).transpose())
      .zip(
        tb.collateral()
          .map(|collateral| collateral.try_into())
          .transpose(),
      )
      .zip(
        tb.required_signers()
          .map(|required_signers| required_signers.try_into())
          .transpose(),
      )
      .map(
        |(((((((inputs, outputs), certs), withdrawals), update), mint), collateral), r_signers)| {
          Self {
            inputs,
            outputs,
            fee: from_bignum(&tb.fee()),
            ttl: tb.ttl().into(),
            certs: certs.into(),
            withdrawals: withdrawals.into(),
            update: update.into(),
            auxiliary_data_hash: tb.auxiliary_data_hash().map(|hash| hash.into()).into(),
            validity_start_interval: tb.validity_start_interval().map(|vsi| vsi.into()).into(),
            mint: mint.into(),
            script_data_hash: tb.script_data_hash().map(|hash| hash.into()).into(),
            collateral: collateral.into(),
            required_signers: r_signers.into(),
            network_id: tb.network_id().map(|network_id| network_id.into()).into(),
          }
        },
      )
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_body_to_bytes(
  transaction_body: TransactionBody, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_body
      .try_into()
      .map(|transaction_body: RTransactionBody| transaction_body.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_body_from_bytes(
  data: CData, result: &mut TransactionBody, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionBody::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_body| transaction_body.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_body_clone(
  transaction_body: TransactionBody, result: &mut TransactionBody, error: &mut CError,
) -> bool {
  handle_exception(|| transaction_body.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_body_free(transaction_body: &mut TransactionBody) {
  transaction_body.free()
}
