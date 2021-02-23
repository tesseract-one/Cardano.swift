use cardano_serialization_lib::address::{NetworkInfo as RNetworkInfo};

pub type NetworkId = u8;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct NetworkInfo {
  network_id: NetworkId,
  protocol_magic: u32,
}

impl From<RNetworkInfo> for NetworkInfo {
  fn from(info: RNetworkInfo) -> Self {
    Self { network_id: info.network_id(), protocol_magic: info.protocol_magic() }
  }
}

impl From<NetworkInfo> for RNetworkInfo {
  fn from(info: NetworkInfo) -> Self {
    Self::new(info.network_id, info.protocol_magic)
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_network_info_mainnet() -> NetworkInfo {
  RNetworkInfo::mainnet().into()
}

#[no_mangle]
pub unsafe extern "C" fn cardano_network_info_testnet() -> NetworkInfo {
  RNetworkInfo::testnet().into()
}