// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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
import CoreData
import Entities

public final class LocalAccessDatasourceProtocolMock: @unchecked Sendable, LocalAccessDatasourceProtocol {

    public init() {}

    // MARK: - getAccess
    public var getAccessUserIdThrowableError1: Error?
    public var closureGetAccess: () -> () = {}
    public var invokedGetAccessfunction = false
    public var invokedGetAccessCount = 0
    public var invokedGetAccessParameters: (userId: String, Void)?
    public var invokedGetAccessParametersList = [(userId: String, Void)]()
    public var stubbedGetAccessResult: UserAccess?

    public func getAccess(userId: String) async throws -> UserAccess? {
        invokedGetAccessfunction = true
        invokedGetAccessCount += 1
        invokedGetAccessParameters = (userId, ())
        invokedGetAccessParametersList.append((userId, ()))
        if let error = getAccessUserIdThrowableError1 {
            throw error
        }
        closureGetAccess()
        return stubbedGetAccessResult
    }
    // MARK: - getAllAccesses
    public var getAllAccessesThrowableError2: Error?
    public var closureGetAllAccesses: () -> () = {}
    public var invokedGetAllAccessesfunction = false
    public var invokedGetAllAccessesCount = 0
    public var stubbedGetAllAccessesResult: [UserAccess]!

    public func getAllAccesses() async throws -> [UserAccess] {
        invokedGetAllAccessesfunction = true
        invokedGetAllAccessesCount += 1
        if let error = getAllAccessesThrowableError2 {
            throw error
        }
        closureGetAllAccesses()
        return stubbedGetAllAccessesResult
    }
    // MARK: - upsert
    public var upsertAccessThrowableError3: Error?
    public var closureUpsert: () -> () = {}
    public var invokedUpsertfunction = false
    public var invokedUpsertCount = 0
    public var invokedUpsertParameters: (access: UserAccess, Void)?
    public var invokedUpsertParametersList = [(access: UserAccess, Void)]()

    public func upsert(access: UserAccess) async throws {
        invokedUpsertfunction = true
        invokedUpsertCount += 1
        invokedUpsertParameters = (access, ())
        invokedUpsertParametersList.append((access, ()))
        if let error = upsertAccessThrowableError3 {
            throw error
        }
        closureUpsert()
    }
    // MARK: - removeAccess
    public var removeAccessUserIdThrowableError4: Error?
    public var closureRemoveAccess: () -> () = {}
    public var invokedRemoveAccessfunction = false
    public var invokedRemoveAccessCount = 0
    public var invokedRemoveAccessParameters: (userId: String, Void)?
    public var invokedRemoveAccessParametersList = [(userId: String, Void)]()

    public func removeAccess(userId: String) async throws {
        invokedRemoveAccessfunction = true
        invokedRemoveAccessCount += 1
        invokedRemoveAccessParameters = (userId, ())
        invokedRemoveAccessParametersList.append((userId, ()))
        if let error = removeAccessUserIdThrowableError4 {
            throw error
        }
        closureRemoveAccess()
    }
}
