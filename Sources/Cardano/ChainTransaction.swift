//
//  ChainTransaction.swift
//  
//
//  Created by Ostap Danylovych on 05.11.2021.
//

import Foundation

public struct ChainTransactionAmount {
    public let unit: String
    public let quantity: String
    
    public init(unit: String, quantity: String) {
        self.unit = unit
        self.quantity = quantity
    }
}

public struct ChainTransaction {
    public let hash: String
    public let block: String
    public let blockHeight: Int
    public let slot: Int
    public let index: Int
    public let outputAmount: [ChainTransactionAmount]
    public let fees: String
    public let deposit: String
    public let size: Int
    public let invalidBefore: String?
    public let invalidHereafter: String?
    public let utxoCount: Int
    public let withdrawalCount: Int
    public let mirCertCount: Int
    public let delegationCount: Int
    public let stakeCertCount: Int
    public let poolUpdateCount: Int
    public let poolRetireCount: Int
    public let assetMintOrBurnCount: Int
    public let redeemerCount: Int
    
    public init(
        hash: String,
        block: String,
        blockHeight: Int,
        slot: Int,
        index: Int,
        outputAmount: [ChainTransactionAmount],
        fees: String,
        deposit: String,
        size: Int,
        invalidBefore: String?,
        invalidHereafter: String?,
        utxoCount: Int,
        withdrawalCount: Int,
        mirCertCount: Int,
        delegationCount: Int,
        stakeCertCount: Int,
        poolUpdateCount: Int,
        poolRetireCount: Int,
        assetMintOrBurnCount: Int,
        redeemerCount: Int
    ) {
        self.hash = hash
        self.block = block
        self.blockHeight = blockHeight
        self.slot = slot
        self.index = index
        self.outputAmount = outputAmount
        self.fees = fees
        self.deposit = deposit
        self.size = size
        self.invalidBefore = invalidBefore
        self.invalidHereafter = invalidHereafter
        self.utxoCount = utxoCount
        self.withdrawalCount = withdrawalCount
        self.mirCertCount = mirCertCount
        self.delegationCount = delegationCount
        self.stakeCertCount = stakeCertCount
        self.poolUpdateCount = poolUpdateCount
        self.poolRetireCount = poolRetireCount
        self.assetMintOrBurnCount = assetMintOrBurnCount
        self.redeemerCount = redeemerCount
    }
}
