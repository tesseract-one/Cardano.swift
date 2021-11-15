use crate::array::*;
use crate::data::CData;
use crate::error::CError;
use crate::int::CInt128;
use crate::linear_fee::Coin;
use crate::panic::*;
use crate::ptr::*;
use crate::stake_credential::StakeCredential;
use cardano_serialization_lib::MIRKind;
use cardano_serialization_lib::{
  utils::{from_bignum, to_bignum},
  MIRPot as RMIRPot, MIRToStakeCredentials as RMIRToStakeCredentials,
  MoveInstantaneousReward as RMoveInstantaneousReward,
  MoveInstantaneousRewardsCert as RMoveInstantaneousRewardsCert,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum MIRPot {
  Reserves,
  Treasury,
}

impl From<MIRPot> for RMIRPot {
  fn from(mir_pot: MIRPot) -> Self {
    match mir_pot {
      MIRPot::Reserves => Self::Reserves,
      MIRPot::Treasury => Self::Treasury,
    }
  }
}

impl From<RMIRPot> for MIRPot {
  fn from(mir_pot: RMIRPot) -> Self {
    match mir_pot {
      RMIRPot::Reserves => Self::Reserves,
      RMIRPot::Treasury => Self::Treasury,
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct MIRToStakeCredentials {
  rewards: CArray<CKeyValue<StakeCredential, CInt128>>,
}

impl Free for CInt128 {
  unsafe fn free(&mut self) {}
}

impl Free for MIRToStakeCredentials {
  unsafe fn free(&mut self) {
    self.rewards.free()
  }
}

impl TryFrom<MIRToStakeCredentials> for RMIRToStakeCredentials {
  type Error = CError;

  fn try_from(mir_to_stake_credentials: MIRToStakeCredentials) -> Result<Self> {
    let map = unsafe { mir_to_stake_credentials.rewards.as_hash_map()? };
    let mut mir_to_stake_credentials = Self::new();
    for (stake_credential, coin) in map {
      mir_to_stake_credentials.insert(&stake_credential.into(), &coin.into());
    }
    Ok(mir_to_stake_credentials)
  }
}

impl TryFrom<RMIRToStakeCredentials> for MIRToStakeCredentials {
  type Error = CError;

  fn try_from(mir_to_stake_credentials: RMIRToStakeCredentials) -> Result<Self> {
    Ok(mir_to_stake_credentials.keys()).and_then(|stake_credentials| {
      (0..stake_credentials.len())
        .map(|index| stake_credentials.get(index))
        .map(|stake_credential| {
          mir_to_stake_credentials
            .get(&stake_credential)
            .ok_or("Cannot get DeltaCoin by StakeCredential".into())
            .zip(stake_credential.try_into())
            .map(|(delta_coin, stake_credential)| (stake_credential, delta_coin.into()).into())
        })
        .collect::<Result<Vec<CKeyValue<StakeCredential, CInt128>>>>()
        .map(|mir_to_stake_credentials| Self {
          rewards: mir_to_stake_credentials.into(),
        })
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mir_to_stake_credentials_clone(
  mir_to_stake_credentials: MIRToStakeCredentials, result: &mut MIRToStakeCredentials,
  error: &mut CError,
) -> bool {
  handle_exception(|| mir_to_stake_credentials.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mir_to_stake_credentials_free(
  mir_to_stake_credentials: &mut MIRToStakeCredentials,
) {
  mir_to_stake_credentials.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum MIREnum {
  ToOtherPot(Coin),
  ToStakeCredentials(MIRToStakeCredentials),
}

impl Free for MIREnum {
  unsafe fn free(&mut self) {
    match self {
      MIREnum::ToStakeCredentials(mir_to_stake_credentials) => mir_to_stake_credentials.free(),
      _ => return,
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mir_enum_clone(
  mir_enum: MIREnum, result: &mut MIREnum, error: &mut CError,
) -> bool {
  handle_exception(|| mir_enum.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_mir_enum_free(mir_enum: &mut MIREnum) {
  mir_enum.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct MoveInstantaneousReward {
  pot: MIRPot,
  variant: MIREnum,
}

impl Free for MoveInstantaneousReward {
  unsafe fn free(&mut self) {
    self.variant.free()
  }
}

impl TryFrom<MoveInstantaneousReward> for RMoveInstantaneousReward {
  type Error = CError;

  fn try_from(mir: MoveInstantaneousReward) -> Result<Self> {
    match mir.variant {
      MIREnum::ToOtherPot(coin) => Ok(Self::new_to_other_pot(mir.pot.into(), &to_bignum(coin))),
      MIREnum::ToStakeCredentials(mir_to_stake_credentials) => mir_to_stake_credentials
        .try_into()
        .map(|mir_to_stake_credentials| {
          Self::new_to_stake_creds(mir.pot.into(), &mir_to_stake_credentials)
        }),
    }
  }
}

impl TryFrom<RMoveInstantaneousReward> for MoveInstantaneousReward {
  type Error = CError;

  fn try_from(mir: RMoveInstantaneousReward) -> Result<Self> {
    match mir.kind() {
      MIRKind::ToOtherPot => mir
        .as_to_other_pot()
        .ok_or("Empty ToOtherPot".into())
        .map(|coin| Self {
          pot: mir.pot().into(),
          variant: MIREnum::ToOtherPot(from_bignum(&coin)),
        }),
      MIRKind::ToStakeCredentials => mir
        .as_to_stake_creds()
        .ok_or("Empty ToStakeCredentials".into())
        .and_then(|mir_to_stake_credentials| mir_to_stake_credentials.try_into())
        .map(|mir_to_stake_credentials| Self {
          pot: mir.pot().into(),
          variant: MIREnum::ToStakeCredentials(mir_to_stake_credentials),
        }),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_reward_from_bytes(
  data: CData, result: &mut MoveInstantaneousReward, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RMoveInstantaneousReward::from_bytes(bytes.to_vec()).into_result())
      .and_then(|move_instantaneous_reward| move_instantaneous_reward.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_reward_to_bytes(
  move_instantaneous_reward: MoveInstantaneousReward, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    move_instantaneous_reward
      .try_into()
      .map(|move_instantaneous_reward: RMoveInstantaneousReward| {
        move_instantaneous_reward.to_bytes()
      })
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_reward_clone(
  mir: MoveInstantaneousReward, result: &mut MoveInstantaneousReward, error: &mut CError,
) -> bool {
  handle_exception(|| mir.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_reward_free(mir: &mut MoveInstantaneousReward) {
  mir.free()
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct MoveInstantaneousRewardsCert {
  move_instantaneous_reward: MoveInstantaneousReward,
}

impl Free for MoveInstantaneousRewardsCert {
  unsafe fn free(&mut self) {
    self.move_instantaneous_reward.free()
  }
}

impl TryFrom<MoveInstantaneousRewardsCert> for RMoveInstantaneousRewardsCert {
  type Error = CError;

  fn try_from(mirs_cert: MoveInstantaneousRewardsCert) -> Result<Self> {
    mirs_cert
      .move_instantaneous_reward
      .try_into()
      .map(|mir| Self::new(&mir))
  }
}

impl TryFrom<RMoveInstantaneousRewardsCert> for MoveInstantaneousRewardsCert {
  type Error = CError;

  fn try_from(mirs_cert: RMoveInstantaneousRewardsCert) -> Result<Self> {
    mirs_cert
      .move_instantaneous_reward()
      .try_into()
      .map(|move_instantaneous_reward| Self {
        move_instantaneous_reward,
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_rewards_cert_clone(
  mirs_cert: MoveInstantaneousRewardsCert, result: &mut MoveInstantaneousRewardsCert,
  error: &mut CError,
) -> bool {
  handle_exception(|| mirs_cert.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_move_instantaneous_rewards_cert_free(
  mirs_cert: &mut MoveInstantaneousRewardsCert,
) {
  mirs_cert.free()
}
