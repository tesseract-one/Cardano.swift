//
//  Certificate.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano

public enum Certificate {
    case stakeRegistration(StakeRegistration)
    case stakeDeregistration(StakeDeregistration)
    case stakeDelegation(StakeDelegation)
    case poolRegistration(PoolRegistration)
    case poolRetirement(PoolRetirement)
    case genesisKeyDelegation(GenesisKeyDelegation)
    case moveInstantaneousRewardsCert(MoveInstantaneousRewardsCert)
    
    init(certificate: CCardano.Certificate) {
        switch certificate.tag {
        case StakeRegistrationKind: self = .stakeRegistration(certificate.stake_registration_kind)
        case StakeDeregistrationKind: self = .stakeDeregistration(certificate.stake_deregistration_kind)
        case StakeDelegationKind: self = .stakeDelegation(certificate.stake_delegation_kind)
        case PoolRegistrationKind: self = .poolRegistration(certificate.pool_registration_kind.copied())
        case PoolRetirementKind: self = .poolRetirement(certificate.pool_retirement_kind)
        case GenesisKeyDelegationKind: self = .genesisKeyDelegation(certificate.genesis_key_delegation_kind)
        case MoveInstantaneousRewardsCertKind: self = .moveInstantaneousRewardsCert(certificate.move_instantaneous_rewards_cert_kind.copied())
        default: fatalError("Unknown Certificate type")
        }
    }
    
    func clonedCCertificate() throws -> CCardano.Certificate {
        try withCCertificate { try $0.clone() }
    }
    
    func withCCertificate<T>(
        fn: @escaping (CCardano.Certificate) throws -> T
    ) rethrows -> T {
        switch self {
        case .stakeRegistration(let stakeRegistration):
            var certificate = CCardano.Certificate()
            certificate.tag = StakeRegistrationKind
            certificate.stake_registration_kind = stakeRegistration
            return try fn(certificate)
        case .stakeDeregistration(let stakeDeregistration):
            var certificate = CCardano.Certificate()
            certificate.tag = StakeDeregistrationKind
            certificate.stake_deregistration_kind = stakeDeregistration
            return try fn(certificate)
        case .stakeDelegation(let stakeDelegation):
            var certificate = CCardano.Certificate()
            certificate.tag = StakeDelegationKind
            certificate.stake_delegation_kind = stakeDelegation
            return try fn(certificate)
        case .poolRegistration(let poolRegistration):
            return try poolRegistration.withCPoolRegistration { poolRegistration in
                var certificate = CCardano.Certificate()
                certificate.tag = PoolRegistrationKind
                certificate.pool_registration_kind = poolRegistration
                return try fn(certificate)
            }
        case .poolRetirement(let poolRetirement):
            var certificate = CCardano.Certificate()
            certificate.tag = PoolRetirementKind
            certificate.pool_retirement_kind = poolRetirement
            return try fn(certificate)
        case .genesisKeyDelegation(let genesisKeyDelegation):
            var certificate = CCardano.Certificate()
            certificate.tag = GenesisKeyDelegationKind
            certificate.genesis_key_delegation_kind = genesisKeyDelegation
            return try fn(certificate)
        case .moveInstantaneousRewardsCert(let mirsCert):
            return try mirsCert.withCMoveInstantaneousRewardsCert { mirsCert in
                var certificate = CCardano.Certificate()
                certificate.tag = MoveInstantaneousRewardsCertKind
                certificate.move_instantaneous_rewards_cert_kind = mirsCert
                return try fn(certificate)
            }
        }
    }
}

extension CCardano.Certificate: CPtr {
    typealias Val = Certificate
    
    func copied() -> Certificate {
        Certificate(certificate: self)
    }
    
    mutating func free() {
        cardano_certificate_free(&self)
    }
}

extension CCardano.Certificate {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_certificate_clone(self, result, error)
        }.get()
    }
}

public typealias Certificates = Array<Certificate>

extension CCardano.Certificates: CArray {
    typealias CElement = CCardano.Certificate
    typealias Val = [CCardano.Certificate]

    mutating func free() {
        cardano_certificates_free(&self)
    }
}

extension Certificates {
    func withCArray<T>(fn: @escaping (CCardano.Certificates) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCCertificate(fn: $1) }, fn: fn)
    }
}
