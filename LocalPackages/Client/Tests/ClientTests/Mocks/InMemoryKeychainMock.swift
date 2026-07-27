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
import os

final class InMemoryKeychainMock: @unchecked Sendable, KeychainProtocol {
    private let storage = OSAllocatedUnfairLock(initialState: [String: Data]())

    var readError: (any Error)?

    func dataOrError(forKey key: String, attributes: [CFString: Any]?) throws -> Data? {
        if let readError { throw readError }
        return storage.withLock { $0[key] }
    }

    func stringOrError(forKey key: String, attributes: [CFString: Any]?) throws -> String? {
        try dataOrError(forKey: key, attributes: attributes)
            .flatMap { String(data: $0, encoding: .utf8) }
    }

    // swiftlint:disable unneeded_throws_rethrows
    func setOrError(_ data: Data, forKey key: String, attributes: [CFString: Any]?) throws {
        storage.withLock { $0[key] = data }
    }

    func setOrError(_ string: String, forKey key: String, attributes: [CFString: Any]?) throws {
        storage.withLock { $0[key] = Data(string.utf8) }
    }

    func removeOrError(forKey key: String) throws {
        storage.withLock { $0[key] = nil }
    }
    // swiftlint:enable unneeded_throws_rethrows
}
