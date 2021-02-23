use cardano_serialization_lib::address::*;

pub enum AddrType {
  Base(BaseAddress),
  Ptr(PointerAddress),
  Enterprise(EnterpriseAddress),
  Reward(RewardAddress),
  Byron(ByronAddress),
}

struct MAddress(AddrType);

impl From<Address> for AddrType {
  fn from(address: Address) -> Self {
    let maddr: MAddress = unsafe { std::mem::transmute(address) };
    maddr.0
  }
}

impl From<AddrType> for Address {
  fn from(t: AddrType) -> Self {
    let maddr = MAddress(t);
    unsafe { std::mem::transmute(maddr) }
  }
}