//
// SafeMutex.swift
// Proton Pass - Created on 03/12/2025.
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

// periphery:ignore:all

import Foundation
import os
import Synchronization

/// A type-erasing protocol for mutex implementations
public protocol MutexProtected<Value>: Sendable {
    associatedtype Value: Sendable

    var value: Value { get }

    func withLock<T: Sendable>(_ block: @Sendable (Value) throws -> T) rethrows -> T

    @discardableResult
    func modify<T: Sendable>(_ block: @Sendable (inout Value) throws -> T) rethrows -> T
}

/// Legacy mutex implementation using OSAllocatedUnfairLock
private final class LegacyMutex<Value: Sendable>: MutexProtected {
    private let lock: OSAllocatedUnfairLock<Value>

    init(_ value: Value) {
        lock = .init(uncheckedState: value)
    }

    var value: Value {
        lock.withLock { $0 }
    }

    func withLock<T: Sendable>(_ block: @Sendable (Value) throws -> T) rethrows -> T {
        try lock.withLock { value in
            try block(value)
        }
    }

    @discardableResult
    func modify<T: Sendable>(_ block: @Sendable (inout Value) throws -> T) rethrows -> T {
        try lock.withLock { state in
            try block(&state)
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
private final class NativeMutex<Value: Sendable>: MutexProtected {
    private let mutex: Mutex<Value>

    init(_ value: Value) {
        mutex = Mutex(value)
    }

    var value: Value {
        mutex.withLock { $0 }
    }

    func withLock<T: Sendable>(_ block: @Sendable (Value) throws -> T) rethrows -> T {
        try mutex.withLock { value in
            try block(value)
        }
    }

    @discardableResult
    func modify<T: Sendable>(_ block: @Sendable (inout Value) throws -> T) rethrows -> T {
        try mutex.withLock { value in
            try block(&value)
        }
    }
}

/// Factory that creates the appropriate mutex implementation based on availability
public enum SafeMutex {
    /// Creates a thread-safe mutex wrapper for the provided value
    /// using the most appropriate implementation based on platform availability.
    /// - Parameter value: The initial value to protect
    /// - Returns: A thread-safe wrapper conforming to MutexProtocol
    public static func create<Value: Sendable>(_ value: Value) -> any MutexProtected<Value> {
        if #available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *) {
            NativeMutex(value)
        } else {
            LegacyMutex(value)
        }
    }
}
