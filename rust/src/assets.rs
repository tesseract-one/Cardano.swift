use super::ptr::*;
use super::array::CArray;
use super::map::*;
use super::asset_name::AssetName;

pub type AssetNames = CArray<AssetName>;

#[no_mangle]
pub unsafe extern "C" fn cardano_asset_names_free(asset_names: &mut AssetNames) {
    asset_names.free();
}

pub type Assets = CMap<AssetName, u64>;

#[no_mangle]
pub unsafe extern "C" fn cardano_assets_free(assets: &mut Assets) {
    assets.free();
}