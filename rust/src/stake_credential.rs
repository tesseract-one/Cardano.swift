use std::convert::{TryInto, TryFrom};
use super::error::CError;
use super::data::CData;
use super::panic::*;
use super::ptr::Ptr;
use cardano_serialization_lib::crypto::{
  Ed25519KeyHash as REd25519KeyHash,
  ScriptHash as RScriptHash
};
use cardano_serialization_lib::address::{StakeCredential as RStakeCredential};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Ed25519KeyHash(pub [u8; 28]);

impl TryFrom<REd25519KeyHash> for Ed25519KeyHash {
  type Error = CError;

  fn try_from(hash: REd25519KeyHash) -> Result<Self> {
    let bytes: [u8; 28] = hash.to_bytes().try_into().map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self(bytes))
  }
}

impl From<Ed25519KeyHash> for REd25519KeyHash {
  fn from(hash: Ed25519KeyHash) -> Self {
    hash.0.into()
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ScriptHash(pub [u8; 28]);

impl TryFrom<RScriptHash> for ScriptHash {
  type Error = CError;

  fn try_from(hash: RScriptHash) -> Result<Self> {
    let bytes: [u8; 28] = hash.to_bytes().try_into().map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self(bytes))
  }
}

impl From<ScriptHash> for RScriptHash {
  fn from(hash: ScriptHash) -> Self {
    hash.0.into()
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum StakeCredential {
  Key(Ed25519KeyHash),
  Script(ScriptHash)
}

impl TryFrom<RStakeCredential> for StakeCredential {
  type Error = CError;

  fn try_from(cred: RStakeCredential) -> Result<Self> {
    match cred.kind() {
      0 => {
        cred.to_keyhash()
          .ok_or_else(|| "Empty Key Hash but kind is 0".into())
          .and_then(|hash| hash.try_into())
          .map(|key| Self::Key(key))
      },
      1 => {
        cred.to_scripthash()
          .ok_or_else(|| "Empty Script Hash but kind is 1".into())
          .and_then(|hash| hash.try_into())
          .map(|key| Self::Script(key))
      },
      _ => Err(format!("Unknown StakeCredential Kind {}", cred.kind()).into())
    }
  }
}

impl From<StakeCredential> for RStakeCredential {
  fn from(cred: StakeCredential) -> Self {
    match cred {
      StakeCredential::Key(hash) => RStakeCredential::from_keyhash(&hash.into()),
      StakeCredential::Script(hash) => RStakeCredential::from_scripthash(&hash.into())
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_stake_credential_from_bytes(
  data: CData, result: &mut StakeCredential, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RStakeCredential::from_bytes(bytes.into()).into_result())
      .and_then(|cred| cred.try_into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_stake_credential_to_bytes(
  cred: StakeCredential, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception(|| {
    let rcred: RStakeCredential = cred.into();
    rcred.to_bytes().into()
  }).response(result, error)
}