//
// RemoteItemKeyDatasourceProtocolMock.swift
// Proton Pass - Created on 02/02/2026.
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

import Client
import Entities
import Foundation

final class RemoteItemKeyDatasourceProtocolMock: @unchecked Sendable, RemoteItemKeyDatasourceProtocol {
    // MARK: - getLatestKey

    var getLatestKeyThrowableError: Error?
    var invokedGetLatestKey = false
    var invokedGetLatestKeyCount = 0
    var invokedGetLatestKeyParameters: (userId: String, shareId: String, itemId: String)?
    var invokedGetLatestKeyParametersList: [(userId: String, shareId: String, itemId: String)] = []
    var stubbedGetLatestKeyResult: ItemKey!

    func getLatestKey(userId: String, shareId: String, itemId: String) async throws -> ItemKey {
        invokedGetLatestKey = true
        invokedGetLatestKeyCount += 1
        invokedGetLatestKeyParameters = (userId, shareId, itemId)
        invokedGetLatestKeyParametersList.append((userId, shareId, itemId))
        if let error = getLatestKeyThrowableError {
            throw error
        }
        return stubbedGetLatestKeyResult
    }

    // MARK: - getAllKeys

    var getAllKeysThrowableError: Error?
    var invokedGetAllKeys = false
    var invokedGetAllKeysCount = 0
    var invokedGetAllKeysParameters: (userId: String, shareId: String, itemId: String)?
    var invokedGetAllKeysParametersList: [(userId: String, shareId: String, itemId: String)] = []
    var stubbedGetAllKeysResult: [ItemKey] = []

    func getAllKeys(userId: String, shareId: String, itemId: String) async throws -> [ItemKey] {
        invokedGetAllKeys = true
        invokedGetAllKeysCount += 1
        invokedGetAllKeysParameters = (userId, shareId, itemId)
        invokedGetAllKeysParametersList.append((userId, shareId, itemId))
        if let error = getAllKeysThrowableError {
            throw error
        }
        return stubbedGetAllKeysResult
    }
}
