//
//  NetworkProvider.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation

public protocol NetworkProvider {
    func getTransaction(hash: String,
                        _ cb: @escaping (Result<Any, Error>) -> Void)
}
