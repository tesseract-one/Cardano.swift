use crate::array::AsHashMap;
use crate::array::CArray;
use crate::array::CKeyValue;
use crate::data::CData;
use crate::error::CError;
use crate::linear_fee::Coin;
use crate::panic::*;
use crate::ptr::*;
use crate::stake_credential::StakeCredential;
use cardano_serialization_lib::utils::from_bignum;
use cardano_serialization_lib::MIRPot as RMIRPot;
use cardano_serialization_lib::{
  address::StakeCredential as RStakeCredential,
  utils::{to_bignum, Coin as RCoin},
  MoveInstantaneousReward as RMoveInstantaneousReward,
  MoveInstantaneousRewardsCert as RMoveInstantaneousRewardsCert,
};
use linked_hash_map::LinkedHashMap;
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
pub struct MoveInstantaneousReward {
  pot: MIRPot,
  rewards: CArray<CKeyValue<StakeCredential, Coin>>,
}

struct TMoveInstantaneousReward {
  pot: RMIRPot,
  _rewards: LinkedHashMap<RStakeCredential, RCoin>,
}

impl Free for MoveInstantaneousReward {
  unsafe fn free(&mut self) {
    self.rewards.free()
  }
}

impl TryFrom<MoveInstantaneousReward> for RMoveInstantaneousReward {
  type Error = CError;

  fn try_from(mir: MoveInstantaneousReward) -> Result<Self> {
    let rewards = unsafe { mir.rewards.as_hash_map()? };
    let mut mir = Self::new(mir.pot.into());
    for (stake_credential, coin) in rewards {
      mir.insert(&stake_credential.into(), &to_bignum(coin));
    }
    Ok(mir)
  }
}

impl TryFrom<RMoveInstantaneousReward> for MoveInstantaneousReward {
  type Error = CError;

  fn try_from(mir: RMoveInstantaneousReward) -> Result<Self> {
    Ok(mir.keys()).and_then(|stake_credentials| {
      (0..stake_credentials.len())
        .map(|index| stake_credentials.get(index))
        .map(|stake_credential| {
          mir
            .get(&stake_credential)
            .ok_or("Cannot get Coin by StakeCredential".into())
            .zip(stake_credential.try_into())
            .map(|(coin, stake_credential)| (stake_credential, from_bignum(&coin)).into())
        })
        .collect::<Result<Vec<CKeyValue<StakeCredential, Coin>>>>()
        .map(|rewards| {
          let mir_t: TMoveInstantaneousReward = unsafe { std::mem::transmute(mir) };
          Self {
            pot: mir_t.pot.into(),
            rewards: rewards.into(),
          }
        })
    })
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
