use crate::address::reward::RewardAddress;
use crate::array::*;
use crate::error::CError;
use crate::linear_fee::Coin;
use crate::panic::*;
use crate::ptr::Free;
use cardano_serialization_lib::{
  utils::{from_bignum, to_bignum},
  Withdrawals as RWithdrawals,
};
use std::convert::{TryFrom, TryInto};

pub type WithdrawalsKeyValue = CKeyValue<RewardAddress, Coin>;
pub type Withdrawals = CArray<WithdrawalsKeyValue>;

impl Free for RewardAddress {
  unsafe fn free(&mut self) {}
}

impl TryFrom<Withdrawals> for RWithdrawals {
  type Error = CError;

  fn try_from(withdrawals: Withdrawals) -> Result<Self> {
    let map = unsafe { withdrawals.as_hash_map()? };
    let mut withdrawals = RWithdrawals::new();
    for (reward_address, coin) in map.into_iter() {
      withdrawals.insert(&reward_address.into(), &to_bignum(coin));
    }
    Ok(withdrawals)
  }
}

impl TryFrom<RWithdrawals> for Withdrawals {
  type Error = CError;

  fn try_from(withdrawals: RWithdrawals) -> Result<Self> {
    Ok(withdrawals.keys()).and_then(|reward_addresses| {
      (0..reward_addresses.len())
        .map(|index| reward_addresses.get(index))
        .map(|reward_address| {
          withdrawals
            .get(&reward_address)
            .ok_or("Cannot get Coin by RewardAddress".into())
            .map(|coin| from_bignum(&coin))
            .zip(reward_address.try_into())
            .map(|(coin, reward_address)| (reward_address, coin).into())
        })
        .collect::<Result<Vec<WithdrawalsKeyValue>>>()
        .map(|withdrawals| withdrawals.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_withdrawals_free(withdrawals: &mut Withdrawals) {
  withdrawals.free()
}
