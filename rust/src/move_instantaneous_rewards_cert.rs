use crate::data::CData;
use crate::error::CError;
use crate::panic::*;
use crate::ptr::*;
use cardano_serialization_lib::{
  MoveInstantaneousReward as RMoveInstantaneousReward,
  MoveInstantaneousRewardsCert as RMoveInstantaneousRewardsCert,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy)]
pub struct MoveInstantaneousReward(CData);

impl Clone for MoveInstantaneousReward {
  fn clone(&self) -> Self {
    let bytes = unsafe { self.0.unowned().expect("Bad bytes pointer") };
    Self(bytes.into())
  }
}

impl Free for MoveInstantaneousReward {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<MoveInstantaneousReward> for RMoveInstantaneousReward {
  type Error = CError;

  fn try_from(mir: MoveInstantaneousReward) -> Result<Self> {
    let bytes = unsafe { mir.0.unowned()? };
    Self::from_bytes(bytes.to_vec()).into_result()
  }
}

impl From<RMoveInstantaneousReward> for MoveInstantaneousReward {
  fn from(mir: RMoveInstantaneousReward) -> Self {
    Self(mir.to_bytes().into())
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
      .map(|move_instantaneous_reward| move_instantaneous_reward.into())
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

impl From<RMoveInstantaneousRewardsCert> for MoveInstantaneousRewardsCert {
  fn from(mirs_cert: RMoveInstantaneousRewardsCert) -> Self {
    Self {
      move_instantaneous_reward: mirs_cert.move_instantaneous_reward().into(),
    }
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
