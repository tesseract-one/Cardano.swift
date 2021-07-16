use crate::array::CArray;
use crate::ptr::Free;
use super::error::CError;
use super::data::CData;
use super::panic::*;
use super::ptr::Ptr;
use cardano_serialization_lib::Ed25519KeyHashes as REd25519KeyHashes;
use cardano_serialization_lib::crypto::{
  Ed25519KeyHash as REd25519KeyHash,
  ScriptHash as RScriptHash
};
use cardano_serialization_lib::address::StakeCredential as RStakeCredential;
use std::convert::{TryInto, TryFrom};

#[repr(C)]
#[derive(Copy, Clone, Hash, PartialEq, Eq)]
pub struct Ed25519KeyHash {
  bytes: [u8; 28],
  len: u8
}

impl Free for Ed25519KeyHash {
  unsafe fn free(&mut self) {}
}

impl TryFrom<REd25519KeyHash> for Ed25519KeyHash {
  type Error = CError;

  fn try_from(hash: REd25519KeyHash) -> Result<Self> {
    let bytes = hash.to_bytes();
    let len = bytes.len() as u8;
    let bytes: [u8; 28] = bytes.try_into().map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self { bytes, len })
  }
}

impl From<Ed25519KeyHash> for REd25519KeyHash {
  fn from(hash: Ed25519KeyHash) -> Self {
    hash.bytes.into()
  }
}

pub type Ed25519KeyHashes = CArray<Ed25519KeyHash>;

impl TryFrom<Ed25519KeyHashes> for REd25519KeyHashes {
  type Error = CError;

  fn try_from(ed25519_key_hashes: Ed25519KeyHashes) -> Result<Self> {
    let vec = unsafe { ed25519_key_hashes.unowned()? };
    let mut ed25519_key_hashes = REd25519KeyHashes::new();
    for ed25519_key_hash in vec.to_vec() {
      ed25519_key_hashes.add(&ed25519_key_hash.into());
    }
    Ok(ed25519_key_hashes)
  }
}

impl TryFrom<REd25519KeyHashes> for Ed25519KeyHashes {
  type Error = CError;

  fn try_from(ed25519_key_hashes: REd25519KeyHashes) -> Result<Self> {
    (0..ed25519_key_hashes.len())
      .map(|index| ed25519_key_hashes.get(index))
      .map(|ed25519_key_hash| ed25519_key_hash.try_into())
      .collect::<Result<Vec<Ed25519KeyHash>>>()
      .map(|ed25519_key_hashes| ed25519_key_hashes.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_ed25519_key_hashes_free(
  ed25519_key_hashes: &mut Ed25519KeyHashes,
) {
  ed25519_key_hashes.free();
}

#[repr(C)]
#[derive(Copy, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct ScriptHash {
  bytes: [u8; 28],
  len: u8
}

impl TryFrom<RScriptHash> for ScriptHash {
  type Error = CError;

  fn try_from(hash: RScriptHash) -> Result<Self> {
    let bytes = hash.to_bytes();
    let len = bytes.len() as u8;
    let bytes: [u8; 28] = bytes.try_into().map_err(|_| CError::DataLengthMismatch)?;
    Ok(Self { bytes, len })
  }
}

impl From<ScriptHash> for RScriptHash {
  fn from(hash: ScriptHash) -> Self {
    hash.bytes.into()
  }
}

#[repr(C)]
#[derive(Copy, Clone, Hash, PartialEq, Eq)]
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
pub unsafe extern "C" fn cardano_ed25519_key_hash_from_bytes(
  data: CData, result: &mut Ed25519KeyHash, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| REd25519KeyHash::from_bytes(bytes.into()).into_result())
      .and_then(|hash| hash.try_into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_ed25519_key_hash_to_bytes(
  hash: Ed25519KeyHash, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception(|| {
    let rhash: REd25519KeyHash = hash.into();
    rhash.to_bytes().into()
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_hash_from_bytes(
  data: CData, result: &mut ScriptHash, error: &mut CError
) -> bool {
  handle_exception_result(|| {
    data.unowned()
      .and_then(|bytes| RScriptHash::from_bytes(bytes.into()).into_result())
      .and_then(|hash| hash.try_into())
  }).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_script_hash_to_bytes(
  hash: ScriptHash, result: &mut CData, error: &mut CError
) -> bool {
  handle_exception(|| {
    let rhash: RScriptHash = hash.into();
    rhash.to_bytes().into()
  }).response(result, error)
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