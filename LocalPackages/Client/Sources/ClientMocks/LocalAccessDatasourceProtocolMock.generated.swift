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
    // MARK: - upsertAccess
    public var upsertAccessThrowableError3: Error?
    public var closureUpsertAccessAsync3: () -> () = {}
    public var invokedUpsertAccessAsync3 = false
    public var invokedUpsertAccessAsyncCount3 = 0
    public var invokedUpsertAccessAsyncParameters3: (access: UserAccess, Void)?
    public var invokedUpsertAccessAsyncParametersList3 = [(access: UserAccess, Void)]()

    public func upsert(access: UserAccess) async throws {
        invokedUpsertAccessAsync3 = true
        invokedUpsertAccessAsyncCount3 += 1
        invokedUpsertAccessAsyncParameters3 = (access, ())
        invokedUpsertAccessAsyncParametersList3.append((access, ()))
        if let error = upsertAccessThrowableError3 {
            throw error
        }
        closureUpsertAccessAsync3()
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
    // MARK: - getPassUserInformations
    public var getPassUserInformationsUserIdThrowableError5: Error?
    public var closureGetPassUserInformations: () -> () = {}
    public var invokedGetPassUserInformationsfunction = false
    public var invokedGetPassUserInformationsCount = 0
    public var invokedGetPassUserInformationsParameters: (userId: String, Void)?
    public var invokedGetPassUserInformationsParametersList = [(userId: String, Void)]()
    public var stubbedGetPassUserInformationsResult: PassUserInformations?

    public func getPassUserInformations(userId: String) async throws -> PassUserInformations? {
        invokedGetPassUserInformationsfunction = true
        invokedGetPassUserInformationsCount += 1
        invokedGetPassUserInformationsParameters = (userId, ())
        invokedGetPassUserInformationsParametersList.append((userId, ()))
        if let error = getPassUserInformationsUserIdThrowableError5 {
            throw error
        }
        closureGetPassUserInformations()
        return stubbedGetPassUserInformationsResult
    }
    // MARK: - upsertInformationsUserId
    public var upsertInformationsUserIdThrowableError6: Error?
    public var closureUpsertInformationsUserIdAsync6: () -> () = {}
    public var invokedUpsertInformationsUserIdAsync6 = false
    public var invokedUpsertInformationsUserIdAsyncCount6 = 0
    public var invokedUpsertInformationsUserIdAsyncParameters6: (informations: PassUserInformations, userId: String)?
    public var invokedUpsertInformationsUserIdAsyncParametersList6 = [(informations: PassUserInformations, userId: String)]()

    public func upsert(informations: PassUserInformations, userId: String) async throws {
        invokedUpsertInformationsUserIdAsync6 = true
        invokedUpsertInformationsUserIdAsyncCount6 += 1
        invokedUpsertInformationsUserIdAsyncParameters6 = (informations, userId)
        invokedUpsertInformationsUserIdAsyncParametersList6.append((informations, userId))
        if let error = upsertInformationsUserIdThrowableError6 {
            throw error
        }
        closureUpsertInformationsUserIdAsync6()
    }
}
