use super::ptr::*;
use super::array::*;
use super::asset_name::AssetName;

pub type AssetNames = CArray<AssetName>;

#[no_mangle]
pub unsafe extern "C" fn cardano_asset_names_free(asset_names: &mut AssetNames) {
    asset_names.free();
}

pub type AssetsKeyValue = CKeyValue<AssetName, u64>;
pub type Assets = CArray<AssetsKeyValue>;

#[no_mangle]
pub unsafe extern "C" fn cardano_assets_free(assets: &mut Assets) {
    assets.free();
}