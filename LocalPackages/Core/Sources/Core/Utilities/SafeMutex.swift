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

import Foundation
import os
import Synchronization

/// Backport of `Synchronization.Mutex` for deployment targets below iOS 18.
///
/// Safety: `@unchecked Sendable` is justified by the same invariant the real
/// `Mutex` relies on (the stdlib declares `extension Mutex: @unchecked Sendable`):
/// - `storage` never escapes; the value is only reachable inside `withLock*`
///   while `lock` is held, so all access is serialized.
/// - `init` takes `consuming sending Value`, so no outside reference to the
///   initial value can survive construction.
/// - `inout sending` on the closure parameter makes smuggling the value out
///   a compile error at call sites (modulo swiftlang/swift#81274, see below).
///
/// Known inherited compiler holes (upstream, not this type's bug — real
/// `Mutex` has them too):
/// - swiftlang/swift#81274: `withLock { $0 }` on a non-Sendable Value
///   currently compiles and lets the protected value escape. Don't do it.
/// - swiftlang/swift#77199 / #81546: assigning an incoming `sending` value
///   *into* the protected state is sometimes rejected even though it's safe
///   (compiler can't prove the closure runs once).
@available(iOS, introduced: 16.0, deprecated: 18.0, message: "Use Synchronization.Mutex")
@available(macOS, introduced: 13.0, deprecated: 15.0, message: "Use Synchronization.Mutex")
public struct SafeMutex<Value: ~Copyable>: ~Copyable, @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock() // OSAllocatedUnfairLock<Void>, pure lock
    private let storage: Storage

    public init(_ initialValue: consuming sending Value) {
        storage = Storage(initialValue)
    }

    public borrowing func withLock<Result: ~Copyable,
        E: Error>(_ body: (inout sending Value) throws(E) -> sending Result) throws(E) -> sending Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&storage.value)
    }

    // periphery:ignore
    public borrowing func withLockIfAvailable<Result: ~Copyable,
        E: Error>(_ body: (inout sending Value) throws(E) -> sending Result) throws(E) -> sending Result? {
        guard lock.lockIfAvailable() else { return nil }
        defer { lock.unlock() }
        return try body(&storage.value)
    }

    private final class Storage {
        var value: Value

        init(_ initialValue: consuming Value) {
            value = initialValue
        }
    }
}
