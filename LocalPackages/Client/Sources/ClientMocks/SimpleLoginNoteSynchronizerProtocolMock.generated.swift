// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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
import Entities

 // Check if the protocol inherits from Actor
public actor SimpleLoginNoteSynchronizerProtocolMock: SimpleLoginNoteSynchronizerProtocol {

    public init() {}

    // MARK: - syncAllAliases
    public var syncAllAliasesUserIdThrowableError1: Error?
    public var closureSyncAllAliases: () -> () = {}
    public var invokedSyncAllAliasesfunction = false
    public var invokedSyncAllAliasesCount = 0
    public var invokedSyncAllAliasesParameters: (userId: String, Void)?
    public var invokedSyncAllAliasesParametersList = [(userId: String, Void)]()
    public var stubbedSyncAllAliasesResult: Bool!

    public func syncAllAliases(userId: String) async throws -> Bool {
        invokedSyncAllAliasesfunction = true
        invokedSyncAllAliasesCount += 1
        invokedSyncAllAliasesParameters = (userId, ())
        invokedSyncAllAliasesParametersList.append((userId, ()))
        if let error = syncAllAliasesUserIdThrowableError1 {
            throw error
        }
        closureSyncAllAliases()
        return stubbedSyncAllAliasesResult
    }
    // MARK: - syncAliases
    public var syncAliasesUserIdAliasesThrowableError2: Error?
    public var closureSyncAliases: () -> () = {}
    public var invokedSyncAliasesfunction = false
    public var invokedSyncAliasesCount = 0
    public var invokedSyncAliasesParameters: (userId: String, aliases: [any ItemIdentifiable])?
    public var invokedSyncAliasesParametersList = [(userId: String, aliases: [any ItemIdentifiable])]()
    public var stubbedSyncAliasesResult: Bool!

    public func syncAliases(userId: String, aliases: [any ItemIdentifiable]) async throws -> Bool {
        invokedSyncAliasesfunction = true
        invokedSyncAliasesCount += 1
        invokedSyncAliasesParameters = (userId, aliases)
        invokedSyncAliasesParametersList.append((userId, aliases))
        if let error = syncAliasesUserIdAliasesThrowableError2 {
            throw error
        }
        closureSyncAliases()
        return stubbedSyncAliasesResult
    }
}
