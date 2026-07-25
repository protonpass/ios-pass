//
// InMemoryKeychainMock.swift
// Proton Pass - Created on 25/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import Foundation

/// Dictionary-backed keychain. Isolation comes for free from allocating one per test, so no
/// teardown is needed — unlike a `UserDefaults`-backed mock, which leaves a persistent domain on
/// disk (or, with `.standard`, writes into the test host's real preferences).
///
/// `@unchecked Sendable`: `KeychainProtocol` requires `Sendable` and the storage is mutable. Each
/// test owns its own instance and drives it from a single task, so there is no concurrent access.
final class InMemoryKeychainMock: @unchecked Sendable, KeychainProtocol {
    private var storage: [String: Data] = [:]

    /// When set, every read fails with it. Simulates the transient failures `AuthManager` has to
    /// survive: keychain locked by data protection, or the symmetric key not yet available.
    var readError: (any Error)?

    /// A missing key returns `nil` and does *not* throw, matching the real keychain: "returns nil
    /// if there was no value in the keychain, throws [only] if the keychain read failed because of
    /// the keychain access error" (ProtonCore `Keychain.dataOrError`). Throwing for "absent" made
    /// `AuthManager` read every empty store as an unreadable one, set `storageLoaded = false` and
    /// then silently skip all persistence for the whole test.
    func dataOrError(forKey key: String, attributes: [CFString: Any]?) throws -> Data? {
        if let readError { throw readError }
        return storage[key]
    }

    func stringOrError(forKey key: String, attributes: [CFString: Any]?) throws -> String? {
        if let readError { throw readError }
        return try dataOrError(forKey: key, attributes: attributes)
            .flatMap { String(data: $0, encoding: .utf8) }
    }

    func setOrError(_ data: Data, forKey key: String, attributes: [CFString: Any]?) throws {
        storage[key] = data
    }

    func setOrError(_ string: String, forKey key: String, attributes: [CFString: Any]?) throws {
        storage[key] = Data(string.utf8)
    }

    func removeOrError(forKey key: String) throws {
        storage[key] = nil
    }
}
