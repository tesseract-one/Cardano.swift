//
//  AsyncMap.swift
//  
//
//  Created by Yehor Popovych on 29.10.2021.
//

import Foundation

public class AsyncMapper<Seq: Sequence, Out, Err: Error> {
    public typealias Mapper = (Seq.Element, @escaping (Result<Out, Err>) -> Void) -> Void
    private let mapper: Mapper
    private let elements: Seq
    private let queue: DispatchQueue
    private var outputs: [Out?]?
    
    
    public init(_ elements: Seq,
                _ mapper: @escaping Mapper) {
        self.elements = elements
        self.mapper = mapper
        self.queue = DispatchQueue(label: "async.mapper.sync.queue", target: .global())
        self.outputs = nil
    }
    
    public func exec(_ result: @escaping (Result<[Out], Err>) -> Void) {
        guard outputs == nil else { return }
        let enumerated = Array(elements.enumerated())
        queue.sync {
            self.outputs = Array(repeating: nil, count: enumerated.count)
        }
        enumerated.forEach { (index, elem) in
            self.mapper(elem) { res in
                self.mapped(index: index, result: res, cb: result)
            }
        }
    }
    
    private func mapped(index: Int,
                        result: Result<Out, Err>,
                        cb: @escaping (Result<[Out], Err>) -> Void) {
        switch result {
        case .success(let out):
            let outputs = queue.sync { () -> [Out?]? in
                guard self.outputs != nil else { return nil }
                guard self.outputs![index] == nil else { return nil }
                self.outputs![index] = out
                let full = self.outputs!.firstIndex { $0 == nil } == nil
                guard full else { return nil }
                let out = self.outputs!
                self.outputs = nil
                return out
            }
            if let out = outputs {
                cb(.success(out.map{ $0! }))
            }
        case .failure(let err):
            let errored = queue.sync { () -> Bool in
                guard self.outputs != nil else { return true }
                self.outputs = nil
                return false
            }
            if !errored { cb(.failure(err)) }
        }
    }
}


extension Sequence {
    public func asyncMap<Out, Err: Error>(
        mapper: @escaping AsyncMapper<Self, Out, Err>.Mapper
    ) -> AsyncMapper<Self, Out, Err> {
        return AsyncMapper(self, mapper)
    }
}
