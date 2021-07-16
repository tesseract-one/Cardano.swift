use crate::address::reward::RewardAddress;
use crate::array::CArray;
use crate::data::CData;
use crate::error::CError;
use crate::genesis_key_delegation::VRFKeyHash;
use crate::linear_fee::Coin;
use crate::option::COption;
use crate::panic::*;
use crate::ptr::*;
use crate::stake_credential::Ed25519KeyHash;
use crate::stake_credential::Ed25519KeyHashes;
use crate::string::CharPtr;
use crate::string::IntoCString;
use crate::transaction_body::MetadataHash;
use crate::transaction_builder::BigNum;
use cardano_serialization_lib::{
  utils::{from_bignum, to_bignum},
  DNSRecordAorAAAA as RDNSRecordAorAAAA, DNSRecordSRV as RDNSRecordSRV, Ipv4 as RIpv4,
  Ipv6 as RIpv6, MultiHostName as RMultiHostName, PoolMetadata as RPoolMetadata,
  PoolParams as RPoolParams, PoolRegistration as RPoolRegistration, Relay as RRelay, RelayKind,
  Relays as RRelays, SingleHostAddr as RSingleHostAddr, SingleHostName as RSingleHostName,
  UnitInterval as RUnitInterval, URL as RURL,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub struct UnitInterval {
  numerator: BigNum,
  denominator: BigNum,
}

impl From<UnitInterval> for RUnitInterval {
  fn from(unit_interval: UnitInterval) -> Self {
    Self::new(
      &to_bignum(unit_interval.numerator),
      &to_bignum(unit_interval.denominator),
    )
  }
}

impl From<RUnitInterval> for UnitInterval {
  fn from(unit_interval: RUnitInterval) -> Self {
    Self {
      numerator: from_bignum(&unit_interval.numerator()),
      denominator: from_bignum(&unit_interval.denominator()),
    }
  }
}

pub type Port = u16;

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Ipv4([u8; 4]);

impl TryFrom<Ipv4> for RIpv4 {
  type Error = CError;

  fn try_from(ipv4: Ipv4) -> Result<Self> {
    Self::new(ipv4.0.to_vec()).into_result()
  }
}

impl From<RIpv4> for Ipv4 {
  fn from(ipv4: RIpv4) -> Self {
    Self(ipv4.ip().try_into().unwrap())
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct Ipv6([u8; 16]);

impl TryFrom<Ipv6> for RIpv6 {
  type Error = CError;

  fn try_from(ipv6: Ipv6) -> Result<Self> {
    Self::new(ipv6.0.to_vec()).into_result()
  }
}

impl From<RIpv6> for Ipv6 {
  fn from(ipv6: RIpv6) -> Self {
    Self(ipv6.ip().try_into().unwrap())
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct SingleHostAddr {
  port: COption<Port>,
  ipv4: COption<Ipv4>,
  ipv6: COption<Ipv6>,
}

impl TryFrom<SingleHostAddr> for RSingleHostAddr {
  type Error = CError;

  fn try_from(single_host_addr: SingleHostAddr) -> Result<Self> {
    let ipv4: Option<Ipv4> = single_host_addr.ipv4.into();
    let ipv6: Option<Ipv6> = single_host_addr.ipv6.into();
    ipv4
      .map(|ipv4| ipv4.try_into())
      .transpose()
      .zip(ipv6.map(|ipv6| ipv6.try_into()).transpose())
      .map(|(ipv4, ipv6)| Self::new(single_host_addr.port.into(), ipv4, ipv6))
  }
}

impl From<RSingleHostAddr> for SingleHostAddr {
  fn from(single_host_addr: RSingleHostAddr) -> Self {
    Self {
      port: single_host_addr.port().into(),
      ipv4: single_host_addr.ipv4().map(|ipv4| ipv4.into()).into(),
      ipv6: single_host_addr.ipv6().map(|ipv6| ipv6.into()).into(),
    }
  }
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct DNSRecordAorAAAA(CharPtr);

impl Free for DNSRecordAorAAAA {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<DNSRecordAorAAAA> for RDNSRecordAorAAAA {
  type Error = CError;

  fn try_from(dns_record_aor_aaaa: DNSRecordAorAAAA) -> Result<Self> {
    let dns_name = unsafe { dns_record_aor_aaaa.0.unowned()? };
    Self::new(dns_name.into()).into_result()
  }
}

impl From<RDNSRecordAorAAAA> for DNSRecordAorAAAA {
  fn from(dns_record_aor_aaaa: RDNSRecordAorAAAA) -> Self {
    Self(dns_record_aor_aaaa.record().into_cstr())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_dns_record_aor_aaaa_clone(
  dns_record_aor_aaaa: DNSRecordAorAAAA, result: &mut DNSRecordAorAAAA, error: &mut CError,
) -> bool {
  handle_exception(|| dns_record_aor_aaaa.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_dns_record_aor_aaaa_free(
  dns_record_aor_aaaa: &mut DNSRecordAorAAAA,
) {
  dns_record_aor_aaaa.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct SingleHostName {
  port: COption<Port>,
  dns_name: DNSRecordAorAAAA,
}

impl Free for SingleHostName {
  unsafe fn free(&mut self) {
    self.dns_name.free()
  }
}

impl TryFrom<SingleHostName> for RSingleHostName {
  type Error = CError;

  fn try_from(single_host_name: SingleHostName) -> Result<Self> {
    single_host_name
      .dns_name
      .try_into()
      .map(|dns_name| Self::new(single_host_name.port.into(), &dns_name))
  }
}

impl From<RSingleHostName> for SingleHostName {
  fn from(single_host_name: RSingleHostName) -> Self {
    Self {
      port: single_host_name.port().into(),
      dns_name: single_host_name.dns_name().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_single_host_name_clone(
  single_host_name: SingleHostName, result: &mut SingleHostName, error: &mut CError,
) -> bool {
  handle_exception(|| single_host_name.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_single_host_name_free(single_host_name: &mut SingleHostName) {
  single_host_name.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct DNSRecordSRV(CharPtr);

impl Free for DNSRecordSRV {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<DNSRecordSRV> for RDNSRecordSRV {
  type Error = CError;

  fn try_from(dns_record_srv: DNSRecordSRV) -> Result<Self> {
    let dns_name = unsafe { dns_record_srv.0.unowned()? };
    Self::new(dns_name.into()).into_result()
  }
}

impl From<RDNSRecordSRV> for DNSRecordSRV {
  fn from(dns_record_srv: RDNSRecordSRV) -> Self {
    Self(dns_record_srv.record().into_cstr())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_dns_record_srv_clone(
  dns_record_srv: DNSRecordSRV, result: &mut DNSRecordSRV, error: &mut CError,
) -> bool {
  handle_exception(|| dns_record_srv.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_dns_record_srv_free(dns_record_srv: &mut DNSRecordSRV) {
  dns_record_srv.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct MultiHostName {
  dns_name: DNSRecordSRV,
}

impl Free for MultiHostName {
  unsafe fn free(&mut self) {
    self.dns_name.free()
  }
}

impl TryFrom<MultiHostName> for RMultiHostName {
  type Error = CError;

  fn try_from(multi_host_name: MultiHostName) -> Result<Self> {
    multi_host_name
      .dns_name
      .try_into()
      .map(|dns_name| Self::new(&dns_name))
  }
}

impl From<RMultiHostName> for MultiHostName {
  fn from(multi_host_name: RMultiHostName) -> Self {
    Self {
      dns_name: multi_host_name.dns_name().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_multi_host_name_clone(
  multi_host_name: MultiHostName, result: &mut MultiHostName, error: &mut CError,
) -> bool {
  handle_exception(|| multi_host_name.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_multi_host_name_free(multi_host_name: &mut MultiHostName) {
  multi_host_name.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub enum Relay {
  SingleHostAddrKind(SingleHostAddr),
  SingleHostNameKind(SingleHostName),
  MultiHostNameKind(MultiHostName),
}

impl Free for Relay {
  unsafe fn free(&mut self) {
    match self {
      Relay::SingleHostNameKind(single_host_name) => single_host_name.free(),
      Relay::MultiHostNameKind(multi_host_name) => multi_host_name.free(),
      _ => return,
    }
  }
}

impl TryFrom<Relay> for RRelay {
  type Error = CError;

  fn try_from(relay: Relay) -> Result<Self> {
    match relay {
      Relay::SingleHostAddrKind(single_host_addr) => single_host_addr
        .try_into()
        .map(|single_host_addr| Self::new_single_host_addr(&single_host_addr)),
      Relay::SingleHostNameKind(single_host_name) => single_host_name
        .try_into()
        .map(|single_host_name| Self::new_single_host_name(&single_host_name)),
      Relay::MultiHostNameKind(multi_host_name) => multi_host_name
        .try_into()
        .map(|multi_host_name| Self::new_multi_host_name(&multi_host_name)),
    }
  }
}

impl TryFrom<RRelay> for Relay {
  type Error = CError;

  fn try_from(relay: RRelay) -> Result<Self> {
    match relay.kind() {
      RelayKind::SingleHostAddr => relay
        .as_single_host_addr()
        .ok_or("Empty SingleHostAddr".into())
        .map(|single_host_addr| Self::SingleHostAddrKind(single_host_addr.into())),
      RelayKind::SingleHostName => relay
        .as_single_host_name()
        .ok_or("Empty SingleHostName".into())
        .map(|single_host_name| Self::SingleHostNameKind(single_host_name.into())),
      RelayKind::MultiHostName => relay
        .as_multi_host_name()
        .ok_or("Empty MultiHostName".into())
        .map(|multi_host_name| Self::MultiHostNameKind(multi_host_name.into())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_relay_clone(
  relay: Relay, result: &mut Relay, error: &mut CError,
) -> bool {
  handle_exception(|| relay.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_relay_free(relay: &mut Relay) {
  relay.free();
}

pub type Relays = CArray<Relay>;

impl TryFrom<Relays> for RRelays {
  type Error = CError;

  fn try_from(relays: Relays) -> Result<Self> {
    let vec = unsafe { relays.unowned()? };
    let mut relays = Self::new();
    for relay in vec.to_vec() {
      let relay = relay.try_into()?;
      relays.add(&relay);
    }
    Ok(relays)
  }
}

impl TryFrom<RRelays> for Relays {
  type Error = CError;

  fn try_from(relays: RRelays) -> Result<Self> {
    (0..relays.len())
      .map(|index| relays.get(index))
      .map(|relay| relay.try_into())
      .collect::<Result<Vec<Relay>>>()
      .map(|relays| relays.into())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_relays_free(relays: &mut Relays) {
  relays.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct URL(CharPtr);

impl Free for URL {
  unsafe fn free(&mut self) {
    self.0.free()
  }
}

impl TryFrom<URL> for RURL {
  type Error = CError;

  fn try_from(url: URL) -> Result<Self> {
    let url = unsafe { url.0.unowned()? };
    Self::new(url.into()).into_result()
  }
}

impl From<RURL> for URL {
  fn from(url: RURL) -> Self {
    Self(url.url().into_cstr())
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_url_clone(url: URL, result: &mut URL, error: &mut CError) -> bool {
  handle_exception(|| url.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_url_free(url: &mut URL) {
  url.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PoolMetadata {
  url: URL,
  metadata_hash: MetadataHash,
}

impl Free for PoolMetadata {
  unsafe fn free(&mut self) {
    self.url.free()
  }
}

impl TryFrom<PoolMetadata> for RPoolMetadata {
  type Error = CError;

  fn try_from(pool_metadata: PoolMetadata) -> Result<Self> {
    pool_metadata
      .url
      .try_into()
      .map(|url| Self::new(&url, &pool_metadata.metadata_hash.into()))
  }
}

impl From<RPoolMetadata> for PoolMetadata {
  fn from(pool_metadata: RPoolMetadata) -> Self {
    Self {
      url: pool_metadata.url().into(),
      metadata_hash: pool_metadata.metadata_hash().into(),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_metadata_clone(
  pool_metadata: PoolMetadata, result: &mut PoolMetadata, error: &mut CError,
) -> bool {
  handle_exception(|| pool_metadata.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_metadata_free(pool_metadata: &mut PoolMetadata) {
  pool_metadata.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PoolParams {
  operator: Ed25519KeyHash,
  vrf_keyhash: VRFKeyHash,
  pledge: Coin,
  cost: Coin,
  margin: UnitInterval,
  reward_account: RewardAddress,
  pool_owners: Ed25519KeyHashes,
  relays: Relays,
  pool_metadata: COption<PoolMetadata>,
}

impl Free for PoolParams {
  unsafe fn free(&mut self) {
    self.pool_owners.free();
    self.relays.free();
    self.pool_metadata.free();
  }
}

impl TryFrom<PoolParams> for RPoolParams {
  type Error = CError;

  fn try_from(pool_params: PoolParams) -> Result<Self> {
    pool_params
      .pool_owners
      .try_into()
      .zip(pool_params.relays.try_into())
      .zip({
        let pool_metadata: Option<PoolMetadata> = pool_params.pool_metadata.into();
        pool_metadata
          .map(|pool_metadata| pool_metadata.try_into())
          .transpose()
      })
      .map(|((pool_owners, relays), pool_metadata)| {
        Self::new(
          &pool_params.operator.into(),
          &pool_params.vrf_keyhash.into(),
          &to_bignum(pool_params.pledge),
          &to_bignum(pool_params.cost),
          &pool_params.margin.into(),
          &pool_params.reward_account.into(),
          &pool_owners,
          &relays,
          pool_metadata,
        )
      })
  }
}

impl TryFrom<RPoolParams> for PoolParams {
  type Error = CError;

  fn try_from(pool_params: RPoolParams) -> Result<Self> {
    pool_params
      .operator()
      .try_into()
      .zip(pool_params.reward_account().try_into())
      .zip(pool_params.pool_owners().try_into())
      .zip(pool_params.relays().try_into())
      .map(|(((operator, reward_account), pool_owners), relays)| Self {
        operator,
        vrf_keyhash: pool_params.vrf_keyhash().into(),
        pledge: from_bignum(&pool_params.pledge()),
        cost: from_bignum(&pool_params.cost()),
        margin: pool_params.margin().into(),
        reward_account,
        pool_owners,
        relays,
        pool_metadata: pool_params
          .pool_metadata()
          .map(|pool_metadata| pool_metadata.into())
          .into(),
      })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_params_clone(
  pool_params: PoolParams, result: &mut PoolParams, error: &mut CError,
) -> bool {
  handle_exception(|| pool_params.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_params_free(pool_params: &mut PoolParams) {
  pool_params.free();
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct PoolRegistration {
  pool_params: PoolParams,
}

impl Free for PoolRegistration {
  unsafe fn free(&mut self) {
    self.pool_params.free()
  }
}

impl TryFrom<PoolRegistration> for RPoolRegistration {
  type Error = CError;

  fn try_from(pool_registration: PoolRegistration) -> Result<Self> {
    pool_registration
      .pool_params
      .try_into()
      .map(|pool_params| Self::new(&pool_params))
  }
}

impl TryFrom<RPoolRegistration> for PoolRegistration {
  type Error = CError;

  fn try_from(pool_registration: RPoolRegistration) -> Result<Self> {
    pool_registration
      .pool_params()
      .try_into()
      .map(|pool_params| Self { pool_params })
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_from_bytes(
  data: CData, result: &mut PoolRegistration, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    data
      .unowned()
      .and_then(|bytes| RPoolRegistration::from_bytes(bytes.to_vec()).into_result())
      .and_then(|pool_registration| pool_registration.try_into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_to_bytes(
  pool_registration: PoolRegistration, result: &mut CData, error: &mut CError,
) -> bool {
  handle_exception_result(|| {
    pool_registration
      .try_into()
      .map(|pool_registration: RPoolRegistration| pool_registration.to_bytes())
      .map(|bytes| bytes.into())
  })
  .response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_clone(
  pool_registration: PoolRegistration, result: &mut PoolRegistration, error: &mut CError,
) -> bool {
  handle_exception(|| pool_registration.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_pool_registration_free(pool_registration: &mut PoolRegistration) {
  pool_registration.free()
}
