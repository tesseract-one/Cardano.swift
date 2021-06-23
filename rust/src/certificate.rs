use crate::array::CArray;
use crate::error::CError;
use crate::genesis_key_delegation::GenesisKeyDelegation;
use crate::move_instantaneous_rewards_cert::MoveInstantaneousRewardsCert;
use crate::panic::*;
use crate::pool_registration::PoolRegistration;
use crate::pool_retirement::PoolRetirement;
use crate::ptr::*;
use crate::stake_delegation::StakeDelegation;
use crate::stake_deregistration::StakeDeregistration;
use crate::stake_registration::StakeRegistration;
use cardano_serialization_lib::{
  Certificate as RCertificate, CertificateKind, Certificates as RCertificates,
};
use std::convert::{TryFrom, TryInto};

#[repr(C)]
#[derive(Copy, Clone)]
pub enum Certificate {
  StakeRegistrationKind(StakeRegistration),
  StakeDeregistrationKind(StakeDeregistration),
  StakeDelegationKind(StakeDelegation),
  PoolRegistrationKind(PoolRegistration),
  PoolRetirementKind(PoolRetirement),
  GenesisKeyDelegationKind(GenesisKeyDelegation),
  MoveInstantaneousRewardsCertKind(MoveInstantaneousRewardsCert),
}

impl Free for Certificate {
  unsafe fn free(&mut self) {
    match self {
      Certificate::PoolRegistrationKind(pool_registration) => pool_registration.free(),
      Certificate::MoveInstantaneousRewardsCertKind(mirs_cert) => mirs_cert.free(),
      _ => return,
    }
  }
}

impl TryFrom<Certificate> for RCertificate {
  type Error = CError;

  fn try_from(certificate: Certificate) -> Result<Self> {
    match certificate {
      Certificate::StakeRegistrationKind(stake_registration) => {
        Ok(Self::new_stake_registration(&stake_registration.into()))
      }
      Certificate::StakeDeregistrationKind(stake_deregistration) => {
        Ok(Self::new_stake_deregistration(&stake_deregistration.into()))
      }
      Certificate::StakeDelegationKind(stake_delegation) => {
        Ok(Self::new_stake_delegation(&stake_delegation.into()))
      }
      Certificate::PoolRegistrationKind(pool_registration) => pool_registration
        .try_into()
        .map(|pool_registration| Self::new_pool_registration(&pool_registration)),
      Certificate::PoolRetirementKind(pool_retirement) => {
        Ok(Self::new_pool_retirement(&pool_retirement.into()))
      }
      Certificate::GenesisKeyDelegationKind(genesis_key_delegation) => Ok(
        Self::new_genesis_key_delegation(&genesis_key_delegation.into()),
      ),
      Certificate::MoveInstantaneousRewardsCertKind(mirs_cert) => mirs_cert
        .try_into()
        .map(|mirs_cert| Self::new_move_instantaneous_rewards_cert(&mirs_cert)),
    }
  }
}

impl TryFrom<RCertificate> for Certificate {
  type Error = CError;

  fn try_from(certificate: RCertificate) -> Result<Self> {
    match certificate.kind() {
      CertificateKind::StakeRegistration => certificate
        .as_stake_registration()
        .ok_or("Empty StakeRegistration".into())
        .and_then(|stake_registration| stake_registration.try_into())
        .map(|stake_registration| Self::StakeRegistrationKind(stake_registration)),
      CertificateKind::StakeDeregistration => certificate
        .as_stake_deregistration()
        .ok_or("Empty StakeDeregistration".into())
        .and_then(|stake_deregistration| stake_deregistration.try_into())
        .map(|stake_deregistration| Self::StakeDeregistrationKind(stake_deregistration)),
      CertificateKind::StakeDelegation => certificate
        .as_stake_delegation()
        .ok_or("Empty StakeDelegation".into())
        .and_then(|stake_delegation| stake_delegation.try_into())
        .map(|stake_delegation| Self::StakeDelegationKind(stake_delegation)),
      CertificateKind::PoolRegistration => certificate
        .as_pool_registration()
        .ok_or("Empty PoolRegistration".into())
        .map(|pool_registration| Self::PoolRegistrationKind(pool_registration.into())),
      CertificateKind::PoolRetirement => certificate
        .as_pool_retirement()
        .ok_or("Empty PoolRetirement".into())
        .and_then(|pool_retirement| pool_retirement.try_into())
        .map(|pool_retirement| Self::PoolRetirementKind(pool_retirement)),
      CertificateKind::GenesisKeyDelegation => certificate
        .as_genesis_key_delegation()
        .ok_or("Empty GenesisKeyDelegation".into())
        .map(|genesis_key_delegation| {
          Self::GenesisKeyDelegationKind(genesis_key_delegation.into())
        }),
      CertificateKind::MoveInstantaneousRewardsCert => certificate
        .as_move_instantaneous_rewards_cert()
        .ok_or("Empty MoveInstantaneousRewardsCert".into())
        .map(|mirs_cert| Self::MoveInstantaneousRewardsCertKind(mirs_cert.into())),
    }
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_certificate_clone(
  certificate: Certificate, result: &mut Certificate, error: &mut CError,
) -> bool {
  handle_exception(|| certificate.clone()).response(result, error)
}

#[no_mangle]
pub unsafe extern "C" fn cardano_certificate_free(certificate: &mut Certificate) {
  certificate.free()
}

pub type Certificates = CArray<Certificate>;

impl TryFrom<RCertificates> for Certificates {
  type Error = CError;

  fn try_from(certificates: RCertificates) -> Result<Self> {
    (0..certificates.len())
      .map(|index| certificates.get(index))
      .map(|certificate| certificate.try_into())
      .collect::<Result<Vec<Certificate>>>()
      .map(|certificates| certificates.into())
  }
}

impl TryFrom<Certificates> for RCertificates {
  type Error = CError;

  fn try_from(certificates: Certificates) -> Result<Self> {
    let vec = unsafe { certificates.unowned()? };
    let mut certificates = RCertificates::new();
    for certificate in vec.to_vec() {
      let certificate = certificate.try_into()?;
      certificates.add(&certificate);
    }
    Ok(certificates)
  }
}

#[no_mangle]
pub unsafe extern "C" fn cardano_certificates_free(certificates: &mut Certificates) {
  certificates.free();
}
