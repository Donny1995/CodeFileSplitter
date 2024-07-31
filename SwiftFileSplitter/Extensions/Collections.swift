//
//  Collections.swift
//  LocalExtensions
//
//  Created by Alexandr Sivash on 10.01.2022.
//

import Foundation

public extension Collection where Index: BinaryInteger {
    
    @inlinable
    func safeGet(index position: Self.Index) -> Self.Element? {
        guard position >= 0 && position < count else { return nil }
        return self[position]
    }
    
    @inlinable
    func nilIfEmpty() -> Self? {
        return isEmpty ? nil : self
    }
}

public extension Dictionary {
    @inlinable
    func nilIfEmpty() -> Self? {
        return isEmpty ? nil : self
    }
}

public protocol OptionalProtocol {
    associatedtype Wrapped
    var optional: Wrapped? { get }
}

extension Optional: OptionalProtocol {
    public var optional: Wrapped? {
        return self
    }
}

public extension Dictionary where Value: OptionalProtocol {
    func filterNils() -> [Key: Value.Wrapped] {
        return self.compactMapValues { item in
            return item.optional
        }
    }
}

public extension Array {
    
    @inlinable func appending(_ newElement: Element) -> [Element] {
        var copy = self
        copy.append(newElement)
        return copy
    }
    
    @inlinable func appending(contentsOf newElements: [Element]) -> [Element] {
        return self + newElements
    }
}
