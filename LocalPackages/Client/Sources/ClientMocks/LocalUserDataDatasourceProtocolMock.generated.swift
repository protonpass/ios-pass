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
import CryptoKit
import Foundation
import ProtonCoreLogin

public final class LocalUserDataDatasourceProtocolMock: @unchecked Sendable, LocalUserDataDatasourceProtocol {

    public init() {}

    // MARK: - getAll
    public var getAllThrowableError1: Error?
    public var closureGetAll: () -> () = {}
    public var invokedGetAllfunction = false
    public var invokedGetAllCount = 0
    public var stubbedGetAllResult: [UserProfile]!

    public func getAll() async throws -> [UserProfile] {
        invokedGetAllfunction = true
        invokedGetAllCount += 1
        if let error = getAllThrowableError1 {
            throw error
        }
        closureGetAll()
        return stubbedGetAllResult
    }
    // MARK: - remove
    public var removeUserIdThrowableError2: Error?
    public var closureRemove: () -> () = {}
    public var invokedRemovefunction = false
    public var invokedRemoveCount = 0
    public var invokedRemoveParameters: (userId: String, Void)?
    public var invokedRemoveParametersList = [(userId: String, Void)]()

    public func remove(userId: String) async throws {
        invokedRemovefunction = true
        invokedRemoveCount += 1
        invokedRemoveParameters = (userId, ())
        invokedRemoveParametersList.append((userId, ()))
        if let error = removeUserIdThrowableError2 {
            throw error
        }
        closureRemove()
    }
    // MARK: - upsert
    public var upsertThrowableError3: Error?
    public var closureUpsert: () -> () = {}
    public var invokedUpsertfunction = false
    public var invokedUpsertCount = 0
    public var invokedUpsertParameters: (userData: UserData, Void)?
    public var invokedUpsertParametersList = [(userData: UserData, Void)]()

    public func upsert(_ userData: UserData) async throws {
        invokedUpsertfunction = true
        invokedUpsertCount += 1
        invokedUpsertParameters = (userData, ())
        invokedUpsertParametersList.append((userData, ()))
        if let error = upsertThrowableError3 {
            throw error
        }
        closureUpsert()
    }
    // MARK: - updateNewActiveUser
    public var updateNewActiveUserUserIdThrowableError4: Error?
    public var closureUpdateNewActiveUser: () -> () = {}
    public var invokedUpdateNewActiveUserfunction = false
    public var invokedUpdateNewActiveUserCount = 0
    public var invokedUpdateNewActiveUserParameters: (userId: String, Void)?
    public var invokedUpdateNewActiveUserParametersList = [(userId: String, Void)]()

    public func updateNewActiveUser(userId: String) async throws {
        invokedUpdateNewActiveUserfunction = true
        invokedUpdateNewActiveUserCount += 1
        invokedUpdateNewActiveUserParameters = (userId, ())
        invokedUpdateNewActiveUserParametersList.append((userId, ()))
        if let error = updateNewActiveUserUserIdThrowableError4 {
            throw error
        }
        closureUpdateNewActiveUser()
    }
    // MARK: - getActiveUser
    public var getActiveUserThrowableError5: Error?
    public var closureGetActiveUser: () -> () = {}
    public var invokedGetActiveUserfunction = false
    public var invokedGetActiveUserCount = 0
    public var stubbedGetActiveUserResult: UserProfile?

    public func getActiveUser() async throws -> UserProfile? {
        invokedGetActiveUserfunction = true
        invokedGetActiveUserCount += 1
        if let error = getActiveUserThrowableError5 {
            throw error
        }
        closureGetActiveUser()
        return stubbedGetActiveUserResult
    }
    // MARK: - removeAll
    public var removeAllThrowableError6: Error?
    public var closureRemoveAll: () -> () = {}
    public var invokedRemoveAllfunction = false
    public var invokedRemoveAllCount = 0

    public func removeAll() async throws {
        invokedRemoveAllfunction = true
        invokedRemoveAllCount += 1
        if let error = removeAllThrowableError6 {
            throw error
        }
        closureRemoveAll()
    }
}
