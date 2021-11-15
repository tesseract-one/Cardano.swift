use crate::address::pointer::Slot;
use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::general_transaction_metadata::GeneralTransactionMetadata;
use crate::option::COption;
use crate::panic::*;
use crate::ptr::*;
use crate::stake_credential::Ed25519KeyHash;
use cardano_serialization_lib::{
  // TODO rename
  metadata::AuxiliaryData as RTransactionMetadata, NativeScript as RNativeScript,
  NativeScriptKind, NativeScripts as RNativeScripts, ScriptAll as RScriptAll,
  ScriptAny as RScriptAny, ScriptHashNamespace as RScriptHashNamespace, ScriptNOfK as RScriptNOfK,
  ScriptPubkey as RScriptPubkey, TimelockExpiry as RTimelockExpiry,
  TimelockStart as RTimelockStart,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum ScriptHashNamespace {
  NativeScriptKind,
}

impl From<ScriptHashNamespace> for RScriptHashNamespace {
  fn from(script_hash_namespace: ScriptHashNamespace) -> Self {
    match script_hash_namespace {
      ScriptHashNamespace::NativeScriptKind => Self::NativeScript,
    }
  }
}

impl From<RScriptHashNamespace> for ScriptHashNamespace {
  fn from(script_hash_namespace: RScriptHashNamespace) -> Self {
    match script_hash_namespace {
      RScriptHashNamespace::NativeScript => Self::NativeScriptKind,
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum NativeScript {
  ScriptPubkeyKind(ScriptPubkey),
  ScriptAllKind(ScriptAll),
  ScriptAnyKind(ScriptAny),
  ScriptNOfKKind(ScriptNOfK),
  TimelockStartKind(TimelockStart),
  TimelockExpiryKind(TimelockExpiry),
}

impl Free for NativeScript {
  unsafe fn free(&mut self) {
    match self {
      NativeScript::ScriptAllKind(script_all) => script_all.free(),
      NativeScript::ScriptAnyKind(script_any) => script_any.free(),
      NativeScript::ScriptNOfKKind(script_n_of_k) => script_n_of_k.free(),
      _ => return,
    }
  }
}

impl TryFrom<NativeScript> for RNativeScript {
  type Error = CError;

  fn try_from(native_script: NativeScript) -> Result<Self> {
    match native_script {
      NativeScript::ScriptPubkeyKind(script_pubkey) => {
        Ok(Self::new_script_pubkey(&script_pubkey.into()))
      }
      NativeScript::ScriptAllKind(script_all) => script_all
        .try_into()
        .map(|script_all| Self::new_script_all(&script_all)),
      NativeScript::ScriptAnyKind(script_any) => script_any
        .try_into()
        .map(|script_any| Self::new_script_any(&script_any)),
      NativeScript::ScriptNOfKKind(script_n_of_k) => script_n_of_k
        .try_into()
        .map(|script_n_of_k| Self::new_script_n_of_k(&script_n_of_k)),
      NativeScript::TimelockStartKind(timelock_start) => {
        Ok(Self::new_timelock_start(&timelock_start.into()))
      }
      NativeScript::TimelockExpiryKind(timelock_expiry) => {
        Ok(Self::new_timelock_expiry(&timelock_expiry.into()))
      }
    }
  }
}

impl TryFrom<RNativeScript> for NativeScript {
  type Error = CError;

  fn try_from(native_script: RNativeScript) -> Result<Self> {
    match native_script.kind() {
      NativeScriptKind::ScriptPubkey => native_script
        .as_script_pubkey()
        .ok_or("Empty ScriptPubkey".into())
        .and_then(|script_pubkey| script_pubkey.try_into())
        .map(|script_pubkey| Self::ScriptPubkeyKind(script_pubkey)),
      NativeScriptKind::ScriptAll => native_script
        .as_script_all()
        .ok_or("Empty ScriptAll".into())
        .and_then(|script_all| script_all.try_into())
        .map(|script_all| Self::ScriptAllKind(script_all)),
      NativeScriptKind::ScriptAny => native_script
        .as_script_any()
        .ok_or("Empty ScriptAny".into())
        .and_then(|script_any| script_any.try_into())
        .map(|script_any| Self::ScriptAnyKind(script_any)),
      NativeScriptKind::ScriptNOfK => native_script
        .as_script_n_of_k()
        .ok_or("Empty ScriptNOfK".into())
        .and_then(|script_n_of_k| script_n_of_k.try_into())
        .map(|script_n_of_k| Self::ScriptNOfKKind(script_n_of_k)),
      NativeScriptKind::TimelockStart => native_script
        .as_timelock_start()
        .ok_or("Empty TimelockStart".into())
        .map(|timelock_start| Self::TimelockStartKind(timelock_start.into())),
      NativeScriptKind::TimelockExpiry => native_script
        .as_timelock_expiry()
        .ok_or("Empty TimelockExpiry".into())
        .map(|timelock_expiry| Self::TimelockExpiryKind(timelock_expiry.into())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_native_script_hash(
  native_script: NativeScript, namespace: ScriptHashNamespace, result: &mut Ed25519KeyHash,
  error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    native_script
      .try_into()
      .map(|native_script: RNativeScript| native_script.hash(namespace.into()))
      .and_then(|key_hash| key_hash.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_native_script_clone(
  native_script: NativeScript, result: &mut NativeScript, error: &mut CError,
) -> bool {
  handle_exception(|| native_script.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_native_script_free(native_script: &mut NativeScript) {
  native_script.free()
}

pub type NativeScripts = CArray<NativeScript>;

impl TryFrom<NativeScripts> for RNativeScripts {
  type Error = CError;

  fn try_from(native_scripts: NativeScripts) -> Result<Self> {
    let vec = unsafe { native_scripts.unowned()? };
    let mut native_scripts = Self::new();
    for native_script in vec.to_vec() {
      let native_script = native_script.try_into()?;
      native_scripts.add(&native_script);
    }
    Ok(native_scripts)
  }
}

impl TryFrom<RNativeScripts> for NativeScripts {
  type Error = CError;

  fn try_from(native_scripts: RNativeScripts) -> Result<Self> {
    (0..native_scripts.len())
      .map(|index| native_scripts.get(index))
      .map(|native_script| native_script.try_into())
      .collect::<Result<Vec<NativeScript>>>()
      .map(|native_scripts| native_scripts.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_native_scripts_free(native_scripts: &mut NativeScripts) {
  native_scripts.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptPubkey {
  addr_keyhash: Ed25519KeyHash,
}

impl From<ScriptPubkey> for RScriptPubkey {
  fn from(script_pubkey: ScriptPubkey) -> Self {
    Self::new(&script_pubkey.addr_keyhash.into())
  }
}

impl TryFrom<RScriptPubkey> for ScriptPubkey {
  type Error = CError;

  fn try_from(script_pubkey: RScriptPubkey) -> Result<Self> {
    script_pubkey
      .addr_keyhash()
      .try_into()
      .map(|addr_keyhash| Self { addr_keyhash })
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptAll {
  native_scripts: NativeScripts,
}

impl Free for ScriptAll {
  unsafe fn free(&mut self) {
    self.native_scripts.free()
  }
}

impl TryFrom<ScriptAll> for RScriptAll {
  type Error = CError;

  fn try_from(script_all: ScriptAll) -> Result<Self> {
    script_all
      .native_scripts
      .try_into()
      .map(|native_scripts| Self::new(&native_scripts))
  }
}

impl TryFrom<RScriptAll> for ScriptAll {
  type Error = CError;

  fn try_from(script_all: RScriptAll) -> Result<Self> {
    script_all
      .native_scripts()
      .try_into()
      .map(|native_scripts| Self { native_scripts })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_all_clone(
  script_all: ScriptAll, result: &mut ScriptAll, error: &mut CError,
) -> bool {
  handle_exception(|| script_all.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_all_free(script_all: &mut ScriptAll) {
  script_all.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptAny {
  native_scripts: NativeScripts,
}

impl Free for ScriptAny {
  unsafe fn free(&mut self) {
    self.native_scripts.free()
  }
}

impl TryFrom<ScriptAny> for RScriptAny {
  type Error = CError;

  fn try_from(script_any: ScriptAny) -> Result<Self> {
    script_any
      .native_scripts
      .try_into()
      .map(|native_scripts| Self::new(&native_scripts))
  }
}

impl TryFrom<RScriptAny> for ScriptAny {
  type Error = CError;

  fn try_from(script_any: RScriptAny) -> Result<Self> {
    script_any
      .native_scripts()
      .try_into()
      .map(|native_scripts| Self { native_scripts })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_any_clone(
  script_any: ScriptAny, result: &mut ScriptAny, error: &mut CError,
) -> bool {
  handle_exception(|| script_any.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_any_free(script_any: &mut ScriptAny) {
  script_any.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptNOfK {
  n: u32,
  native_scripts: NativeScripts,
}

impl Free for ScriptNOfK {
  unsafe fn free(&mut self) {
    self.native_scripts.free()
  }
}

impl TryFrom<ScriptNOfK> for RScriptNOfK {
  type Error = CError;

  fn try_from(script_n_of_k: ScriptNOfK) -> Result<Self> {
    script_n_of_k
      .native_scripts
      .try_into()
      .map(|native_scripts| Self::new(script_n_of_k.n, &native_scripts))
  }
}

impl TryFrom<RScriptNOfK> for ScriptNOfK {
  type Error = CError;

  fn try_from(script_n_of_k: RScriptNOfK) -> Result<Self> {
    script_n_of_k
      .native_scripts()
      .try_into()
      .map(|native_scripts| Self {
        n: script_n_of_k.n(),
        native_scripts,
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_n_of_k_clone(
  script_n_of_k: ScriptNOfK, result: &mut ScriptNOfK, error: &mut CError,
) -> bool {
  handle_exception(|| script_n_of_k.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_n_of_k_free(script_n_of_k: &mut ScriptNOfK) {
  script_n_of_k.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TimelockStart {
  slot: Slot,
}

impl From<TimelockStart> for RTimelockStart {
  fn from(timelock_start: TimelockStart) -> Self {
    Self::new(timelock_start.slot)
  }
}

impl From<RTimelockStart> for TimelockStart {
  fn from(timelock_start: RTimelockStart) -> Self {
    Self {
      slot: timelock_start.slot(),
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TimelockExpiry {
  slot: Slot,
}

impl From<TimelockExpiry> for RTimelockExpiry {
  fn from(timelock_expiry: TimelockExpiry) -> Self {
    Self::new(timelock_expiry.slot)
  }
}

impl From<RTimelockExpiry> for TimelockExpiry {
  fn from(timelock_expiry: RTimelockExpiry) -> Self {
    Self {
      slot: timelock_expiry.slot(),
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionMetadata {
  general: GeneralTransactionMetadata,
  native_scripts: COption<NativeScripts>,
}

impl Free for TransactionMetadata {
  unsafe fn free(&mut self) {
    self.general.free();
    self.native_scripts.free();
  }
}

impl TryFrom<TransactionMetadata> for RTransactionMetadata {
  type Error = CError;

  fn try_from(transaction_metadata: TransactionMetadata) -> Result<Self> {
    todo!();
    // transaction_metadata
    //   .general
    //   .try_into()
    //   .zip({
    //     let native_scripts: Option<NativeScripts> = transaction_metadata.native_scripts.into();
    //     native_scripts.map(|ns| ns.try_into()).transpose()
    //   })
    //   .map(|(general, native_scripts)| {
    //     let mut transaction_metadata = Self::new(&general);
    //     native_scripts.map(|ns| transaction_metadata.set_native_scripts(&ns));
    //     transaction_metadata
    //   })
  }
}

impl TryFrom<RTransactionMetadata> for TransactionMetadata {
  type Error = CError;

  fn try_from(transaction_metadata: RTransactionMetadata) -> Result<Self> {
    todo!();
    // transaction_metadata
    //   .general()
    //   .try_into()
    //   .zip(
    //     transaction_metadata
    //       .native_scripts()
    //       .map(|native_scripts| native_scripts.try_into())
    //       .transpose(),
    //   )
    //   .map(|(general, native_scripts)| Self {
    //     general,
    //     native_scripts: native_scripts.into(),
    //   })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadata_to_bytes(
  transaction_metadata: TransactionMetadata, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    transaction_metadata
      .try_into()
      .map(|transaction_metadata: RTransactionMetadata| transaction_metadata.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadata_from_bytes(
  data: CData, result: &mut TransactionMetadata, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RTransactionMetadata::from_bytes(bytes.to_vec()).into_result())
      .and_then(|transaction_metadata| transaction_metadata.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadata_clone(
  transaction_metadata: TransactionMetadata, result: &mut TransactionMetadata, error: &mut CError,
) -> bool {
  handle_exception(|| transaction_metadata.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_transaction_metadata_free(
  transaction_metadata: &mut TransactionMetadata,
) {
  transaction_metadata.free()
}
