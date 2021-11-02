//
//  SimpleSignatureProvider.swift
//  
//
//  Created by Ostap Danylovych on 02.11.2021.
//

import Foundation

public struct SimpleSignatureProvider: SignatureProvider {
    public func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        fatalError("Not implemented")
    }
    
    public func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}
