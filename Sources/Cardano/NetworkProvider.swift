//
//  NetworkProvider.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public protocol NetworkProvider {
    func getSlotNumber(_ cb: @escaping (Result<Int?, Error>) -> Void)
    
    func getBalance(for address: Address,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void)
    
    func getTransactions(for address: Address,
                         _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void)
    
    func getTransactionCount(for address: Address,
                             _ cb: @escaping (Result<Int, Error>) -> Void)
    
    func getTransaction(hash: String,
                        _ cb: @escaping (Result<ChainTransaction?, Error>) -> Void)
    
    func getUtxos(for addresses: [Address],
                  page: Int,
                  _ cb: @escaping (Result<[UTXO], Error>) -> Void)
    
    func getUtxos(for transaction: TransactionHash,
                  _ cb: @escaping (Result<[UTXO], Error>) -> Void)
    
    func submit(tx: Transaction,
                _ cb: @escaping (Result<String, Error>) -> Void)
}
