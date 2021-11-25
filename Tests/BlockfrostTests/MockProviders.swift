//
//  MockProviders.swift
//  
//
//  Created by Yehor Popovych on 25.11.2021.
//

import Foundation
import Cardano

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
