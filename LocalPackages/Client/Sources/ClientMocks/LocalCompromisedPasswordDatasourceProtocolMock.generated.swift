// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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
import Core
import CoreData
import Entities
import Foundation

public final class LocalCompromisedPasswordDatasourceProtocolMock: @unchecked Sendable, LocalCompromisedPasswordDatasourceProtocol {

    public init() {}

    // MARK: - getChecks
    public var getChecksUserIdThrowableError1: Error?
    public var closureGetChecks: () -> () = {}
    public var invokedGetChecksfunction = false
    public var invokedGetChecksCount = 0
    public var invokedGetChecksParameters: (userId: String, Void)?
    public var invokedGetChecksParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetChecksResult: [CompromisedPasswordCheck]!

    public func getChecks(userId: String) async throws -> [CompromisedPasswordCheck] {
        invokedGetChecksfunction = true
        invokedGetChecksCount += 1
        invokedGetChecksParameters = (userId, ())
        if let error = getChecksUserIdThrowableError1 {
            throw error
        }
        closureGetChecks()
        return stubbedGetChecksResult
    }
    // MARK: - upsert
    public var upsertUserIdThrowableError2: Error?
    public var closureUpsert: () -> () = {}
    public var invokedUpsertfunction = false
    public var invokedUpsertCount = 0
    public var invokedUpsertParameters: (checks: [CompromisedPasswordCheck], userId: String)?
    public var invokedUpsertParametersList = [(checks: [CompromisedPasswordCheck], userId: String)]()

    public func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws {
        invokedUpsertfunction = true
        invokedUpsertCount += 1
        invokedUpsertParameters = (checks, userId)
        if let error = upsertUserIdThrowableError2 {
            throw error
        }
        closureUpsert()
    }
    // MARK: - remove
    public var removeUserIdStaleItemIdsThrowableError3: Error?
    public var closureRemove: () -> () = {}
    public var invokedRemovefunction = false
    public var invokedRemoveCount = 0
    public var invokedRemoveParameters: (userId: String, staleItemIds: [any ItemIdentifiable])?
    public var invokedRemoveParametersList = [(userId: String, staleItemIds: [any ItemIdentifiable])]()

    public func remove(userId: String, staleItemIds: [any ItemIdentifiable]) async throws {
        invokedRemovefunction = true
        invokedRemoveCount += 1
        invokedRemoveParameters = (userId, staleItemIds)
        if let error = removeUserIdStaleItemIdsThrowableError3 {
            throw error
        }
        closureRemove()
    }
    // MARK: - removeAll
    public var removeAllUserIdThrowableError4: Error?
    public var closureRemoveAll: () -> () = {}
    public var invokedRemoveAllfunction = false
    public var invokedRemoveAllCount = 0
    public var invokedRemoveAllParameters: (userId: String, Void)?
    public var invokedRemoveAllParametersList = [(userId: String, Void)]()

    public func removeAll(userId: String) async throws {
        invokedRemoveAllfunction = true
        invokedRemoveAllCount += 1
        invokedRemoveAllParameters = (userId, ())
        if let error = removeAllUserIdThrowableError4 {
            throw error
        }
        closureRemoveAll()
    }
}
