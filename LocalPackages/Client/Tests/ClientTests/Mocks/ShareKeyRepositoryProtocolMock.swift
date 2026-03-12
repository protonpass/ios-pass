//
// ShareKeyRepositoryProtocolMock.swift
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

final class ShareKeyRepositoryProtocolMock: @unchecked Sendable, ShareKeyRepositoryProtocol {
    // MARK: - getAllLocalKeys

    var getAllLocalKeysThrowableError: Error?
    var invokedGetAllLocalKeys = false
    var invokedGetAllLocalKeysCount = 0
    var stubbedGetAllLocalKeysResult: [SymmetricallyEncryptedShareKey] = []

    func getAllLocalKeys() async throws -> [SymmetricallyEncryptedShareKey] {
        invokedGetAllLocalKeys = true
        invokedGetAllLocalKeysCount += 1
        if let error = getAllLocalKeysThrowableError {
            throw error
        }
        return stubbedGetAllLocalKeysResult
    }

    // MARK: - getKeys

    var getKeysThrowableError: Error?
    var invokedGetKeys = false
    var invokedGetKeysCount = 0
    var invokedGetKeysParameters: (userId: String, shareId: String)?
    var invokedGetKeysParametersList: [(userId: String, shareId: String)] = []
    var stubbedGetKeysResult: [SymmetricallyEncryptedShareKey] = []

    func getKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        invokedGetKeys = true
        invokedGetKeysCount += 1
        invokedGetKeysParameters = (userId, shareId)
        invokedGetKeysParametersList.append((userId, shareId))
        if let error = getKeysThrowableError {
            throw error
        }
        return stubbedGetKeysResult
    }

    // MARK: - refreshKeys

    var refreshKeysThrowableError: Error?
    var invokedRefreshKeys = false
    var invokedRefreshKeysCount = 0
    var invokedRefreshKeysParameters: (userId: String, shareId: String)?
    var invokedRefreshKeysParametersList: [(userId: String, shareId: String)] = []
    var stubbedRefreshKeysResult: [SymmetricallyEncryptedShareKey] = []

    func refreshKeys(userId: String, shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        invokedRefreshKeys = true
        invokedRefreshKeysCount += 1
        invokedRefreshKeysParameters = (userId, shareId)
        invokedRefreshKeysParametersList.append((userId, shareId))
        if let error = refreshKeysThrowableError {
            throw error
        }
        return stubbedRefreshKeysResult
    }

    // MARK: - deleteAllCurrentUserShareKeysLocally

    var deleteAllUserShareKeysLocallyThrowableError: Error?
    var invokedDeleteAllUserShareKeysLocally = false
    var invokedDeleteAllUserShareKeysLocallyCount = 0
    var invokedDeleteAllUserShareKeysLocallyParameters: (userId: String, Void)?
    var invokedDeleteAllUserShareKeysLocallyParametersList: [(userId: String, Void)] = []

    func deleteAllUserShareKeysLocally(userId: String) async throws {
        invokedDeleteAllUserShareKeysLocally = true
        invokedDeleteAllUserShareKeysLocallyCount += 1
        invokedDeleteAllUserShareKeysLocallyParameters = (userId, ())
        invokedDeleteAllUserShareKeysLocallyParametersList.append((userId, ()))
        if let error = deleteAllUserShareKeysLocallyThrowableError {
            throw error
        }
    }
}
