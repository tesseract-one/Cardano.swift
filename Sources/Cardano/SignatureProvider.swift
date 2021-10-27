//
//  SignatureProvider.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public protocol SignatureProvider {
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void)
    func sign(tx: TransactionBody, metadata: TransactionMetadata?, _ cb: @escaping (Result<Transaction, Error>) -> Void)
}
