//
//  TransactionMetadatumLabels.swift
//  
//
//  Created by Ostap Danylovych on 02.07.2021.
//

import Foundation
import CCardano

public typealias TransactionMetadatumLabels = Array<TransactionMetadatumLabel>

extension CCardano.TransactionMetadatumLabels: CArray {
    typealias CElement = TransactionMetadatumLabel
    typealias Val = [TransactionMetadatumLabel]

    mutating func free() {
        cardano_transaction_metadatum_labels_free(&self)
    }
}

extension TransactionMetadatumLabels {
    func withCArray<T>(fn: @escaping (CCardano.TransactionMetadatumLabels) throws -> T) rethrows -> T {
        try withCArr(fn: fn)
    }
}
