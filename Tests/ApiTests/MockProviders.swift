//
//  MockProviders.swift
//  
//
//  Created by Ostap Danylovych on 19.11.2021.
//

import Foundation
import Cardano

struct NetworkProviderMock: NetworkProvider {
    var getSlotNumberMock: ((_ cb: @escaping (Result<Int?, Error>) -> Void) -> Void)?
    var getBalanceMock: ((Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) -> Void)?
    var getTransactionsMock: ((Address, _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) -> Void)?
    var getTransactionCountMock: ((Address, _ cb: @escaping (Result<Int, Error>) -> Void) -> Void)?
    var getTransactionMock: ((TransactionHash, _ cb: @escaping (Result<ChainTransaction?, Error>) -> Void) -> Void)?
    var getUtxosForAddressesMock: (([Address], Int, _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) -> Void)?
    var getUtxosForTransactionMock: ((TransactionHash, _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) -> Void)?
    var submitMock: ((Transaction, _ cb: @escaping (Result<TransactionHash, Error>) -> Void) -> Void)?
    
    func getSlotNumber(_ cb: @escaping (Result<Int?, Error>) -> Void) {
        getSlotNumberMock!(cb)
    }
    
    func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        getBalanceMock!(address, cb)
    }
    
    func getTransactions(for address: Address,
                         _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) {
        getTransactionsMock!(address, cb)
    }
    
    func getTransactionCount(for address: Address,
                             _ cb: @escaping (Result<Int, Error>) -> Void) {
        getTransactionCountMock!(address, cb)
    }
    
    func getTransaction(hash: TransactionHash,
                        _ cb: @escaping (Result<ChainTransaction?, Error>) -> Void) {
        getTransactionMock!(hash, cb)
    }
    
    func getUtxos(for addresses: [Address],
                  page: Int,
                  _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) {
        getUtxosForAddressesMock!(addresses, page, cb)
    }
    
    func getUtxos(for transaction: TransactionHash,
                  _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) {
        getUtxosForTransactionMock!(transaction, cb)
    }
    
    func submit(tx: Transaction,
                _ cb: @escaping (Result<TransactionHash, Error>) -> Void) {
        submitMock!(tx, cb)
    }
}

struct SignatureProviderMock: SignatureProvider {
    var accountsMock: ((_ cb: @escaping (Result<[Account], Error>) -> Void) -> Void)?
    var signMock: ((ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) -> Void)?
    
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        accountsMock!(cb)
    }
    
    func sign(tx: ExtendedTransaction,
              _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        signMock!(tx, cb)
    }
}

struct AddressManagerMock: AddressManager {
    var accountsMock: ((_ cb: @escaping (Result<[Account], Error>) -> Void) -> Void)?
    var newMock: ((Account, Bool) throws -> Address)?
    var getCachedMock: ((Account) throws -> [Address])?
    var getForAccountMock: ((Account, _ cb: @escaping (Result<[Address], Error>) -> Void) -> Void)?
    var fetchForAccountsMock: (([Account], _ cb: @escaping (Result<Void, Error>) -> Void) -> Void)?
    var fetchMock: ((_ cb: @escaping (Result<Void, Error>) -> Void) -> Void)?
    var fetchedAccountsMock: (() -> [Account])?
    var extendedMock: (([Address]) throws -> [ExtendedAddress])?
    
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        accountsMock!(cb)
    }
    
    func new(for account: Account, change: Bool) throws -> Address {
        try newMock!(account, change)
    }
    
    func get(cached account: Account) throws -> [Address] {
        try getCachedMock!(account)
    }
    
    func get(for account: Account,
             _ cb: @escaping (Result<[Address], Error>) -> Void) {
        getForAccountMock!(account, cb)
    }
    
    func fetch(for accounts: [Account],
               _ cb: @escaping (Result<Void, Error>) -> Void) {
        fetchForAccountsMock!(accounts, cb)
    }
    
    func fetch(_ cb: @escaping (Result<Void, Error>) -> Void) {
        fetchMock!(cb)
    }
    
    func fetchedAccounts() -> [Account] {
        fetchedAccountsMock!()
    }
    
    func extended(addresses: [Address]) throws -> [ExtendedAddress] {
        try extendedMock!(addresses)
    }
}

struct UtxoProviderMock: UtxoProvider {
    var utxoIteratorNextMock: ((_ cb: @escaping (Result<[TransactionUnspentOutput], Error>, UtxoIteratorMock?) -> Void) -> Void)?
    var getForTransactionMock: ((TransactionHash, _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) -> Void)?
    
    struct UtxoIteratorMock: UtxoProviderAsyncIterator {
        let utxoIteratorNextMock: ((_ cb: @escaping (Result<[TransactionUnspentOutput], Error>, UtxoIteratorMock?) -> Void) -> Void)?
        
        func next(_ cb: @escaping (Result<[TransactionUnspentOutput], Error>, Self?) -> Void) {
            utxoIteratorNextMock!(cb)
        }
    }
    
    func get(for addresses: [Address], asset: (PolicyID, AssetName)?) -> UtxoProviderAsyncIterator {
        UtxoIteratorMock(utxoIteratorNextMock: utxoIteratorNextMock)
    }
    
    func get(for transaction: TransactionHash, _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) {
        getForTransactionMock!(transaction, cb)
    }
}
