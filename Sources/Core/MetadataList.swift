//
//  MetadataList.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

public typealias MetadataList = Array<TransactionMetadatum>

extension CCardano.MetadataList: CArray {
    typealias CElement = CCardano.TransactionMetadatum
    typealias Val = [CCardano.TransactionMetadatum]

    mutating func free() {
        cardano_metadata_list_free(&self)
    }
}

extension MetadataList {
    func withCArray<T>(fn: @escaping (CCardano.MetadataList) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCTransactionMetadatum(fn: $1) }, fn: fn)
    }
}
