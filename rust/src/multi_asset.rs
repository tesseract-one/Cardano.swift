use super::array::*;
use super::assets::Assets;
use super::error::CError;
use super::panic::*;
use super::ptr::Free;
use super::stake_credential::ScriptHash;
use cardano_serialization_lib::MultiAsset as RMultiAsset;
use std::convert::{TryFrom, TryInto};

pub type PolicyID = ScriptHash;
pub type MultiAssetKeyValue = CKeyValue<PolicyID, Assets>;
pub type MultiAsset = CArray<MultiAssetKeyValue>;

impl Free for PolicyID {
  unsafe fn free(&mut self) {}
}

impl TryFrom<MultiAsset> for RMultiAsset {
  type Error = CError;

  fn try_from(multi_asset: MultiAsset) -> Result<Self> {
    let map = unsafe { multi_asset.as_btree_map()? };
    let mut multi_asset = RMultiAsset::new();
    for (pid, assets) in map {
      let assets = assets.try_into()?;
      multi_asset.insert(&pid.into(), &assets);
    }
    Ok(multi_asset)
  }
}

impl TryFrom<RMultiAsset> for MultiAsset {
  type Error = CError;

  fn try_from(multi_asset: RMultiAsset) -> Result<Self> {
    Ok(multi_asset.keys()).and_then(|pids| {
      (0..pids.len())
        .map(|index| pids.get(index))
        .map(|pid| {
          multi_asset
            .get(&pid)
            .ok_or("Cannot get Assets by PolicyID".into())
            .and_then(|assets| assets.try_into())
            .zip(pid.try_into())
            .map(|(assets, pid)| (pid, assets).into())
        })
        .collect::<Result<Vec<MultiAssetKeyValue>>>()
        .map(|multi_asset| multi_asset.into())
    })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_multi_asset_sub(
  multi_asset: MultiAsset, rhs_ma: MultiAsset, result: &mut MultiAsset, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    multi_asset
      .try_into()
      .zip(rhs_ma.try_into())
      .map(|(multi_asset, rhs_ma): (RMultiAsset, RMultiAsset)| multi_asset.sub(&rhs_ma))
      .and_then(|multi_asset| multi_asset.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_multi_asset_free(multi_asset: &mut MultiAsset) {
  multi_asset.free()
}
