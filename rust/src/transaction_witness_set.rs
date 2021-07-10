use crate::bootstrap_witness::BootstrapWitnesses;
use crate::error::CError;
use crate::option::COption;
use crate::panic::*;
use crate::ptr::Free;
use crate::transaction_metadata::NativeScripts;
use crate::vkeywitness::Vkeywitnesses;
use cardano_serialization_lib::TransactionWitnessSet as RTransactionWitnessSet;
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct TransactionWitnessSet {
  vkeys: COption<Vkeywitnesses>,
  scripts: COption<NativeScripts>,
  bootstraps: COption<BootstrapWitnesses>,
}

impl Free for TransactionWitnessSet {
  unsafe fn free(&mut self) {
    self.vkeys.free();
    self.scripts.free();
    self.bootstraps.free();
  }
}

impl TryFrom<RTransactionWitnessSet> for TransactionWitnessSet {
  type Error = CError;

  fn try_from(transaction_witness_set: RTransactionWitnessSet) -> Result<Self> {
    transaction_witness_set
      .scripts()
      .map(|native_scripts| native_scripts.try_into())
      .transpose()
      .map(|native_scripts| Self {
        vkeys: transaction_witness_set
          .vkeys()
          .map(|vkeywitnesses| vkeywitnesses.into())
          .into(),
        scripts: native_scripts.into(),
        bootstraps: transaction_witness_set
          .bootstraps()
          .map(|bootstrap_witnesses| bootstrap_witnesses.into())
          .into(),
      })
  }
}

impl TryFrom<TransactionWitnessSet> for RTransactionWitnessSet {
  type Error = CError;

  fn try_from(transaction_witness_set: TransactionWitnessSet) -> Result<Self> {
    let vkeys: Option<Vkeywitnesses> = transaction_witness_set.vkeys.into();
    let scripts: Option<NativeScripts> = transaction_witness_set.scripts.into();
    let bootstraps: Option<BootstrapWitnesses> = transaction_witness_set.bootstraps.into();
    let mut transaction_witness_set = RTransactionWitnessSet::new();
    if let Some(vkeys) = vkeys {
      let vkeys = vkeys.try_into()?;
      transaction_witness_set.set_vkeys(&vkeys);
    }
    if let Some(scripts) = scripts {
      let scripts = scripts.try_into()?;
      transaction_witness_set.set_scripts(&scripts);
    }
    if let Some(bootstraps) = bootstraps {
      let bootstraps = bootstraps.try_into()?;
      transaction_witness_set.set_bootstraps(&bootstraps);
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
