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
import CoreData
import Entities

public final class LocalInviteDatasourceProtocolMock: @unchecked Sendable, LocalInviteDatasourceProtocol {

    public init() {}

    // MARK: - getUserInvites
    public var getUserInvitesUserIdThrowableError1: Error?
    public var closureGetUserInvites: () -> () = {}
    public var invokedGetUserInvitesfunction = false
    public var invokedGetUserInvitesCount = 0
    public var invokedGetUserInvitesParameters: (userId: String, Void)?
    public var invokedGetUserInvitesParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetUserInvitesResult: [UserInvite]!

    public func getUserInvites(userId: String) async throws -> [UserInvite] {
        invokedGetUserInvitesfunction = true
        invokedGetUserInvitesCount += 1
        invokedGetUserInvitesParameters = (userId, ())
        if let error = getUserInvitesUserIdThrowableError1 {
            throw error
        }
        closureGetUserInvites()
        return stubbedGetUserInvitesResult
    }
    // MARK: - upsertUserInvites
    public var upsertUserInvitesUserIdInvitesThrowableError2: Error?
    public var closureUpsertUserInvites: () -> () = {}
    public var invokedUpsertUserInvitesfunction = false
    public var invokedUpsertUserInvitesCount = 0
    public var invokedUpsertUserInvitesParameters: (userId: String, invites: [UserInvite])?
    public var invokedUpsertUserInvitesParametersList = [(userId: String, invites: [UserInvite])]()

    public func upsertUserInvites(userId: String, invites: [UserInvite]) async throws {
        invokedUpsertUserInvitesfunction = true
        invokedUpsertUserInvitesCount += 1
        invokedUpsertUserInvitesParameters = (userId, invites)
        if let error = upsertUserInvitesUserIdInvitesThrowableError2 {
            throw error
        }
        closureUpsertUserInvites()
    }
    // MARK: - removeUserInvites
    public var removeUserInvitesUserIdInvitesThrowableError3: Error?
    public var closureRemoveUserInvites: () -> () = {}
    public var invokedRemoveUserInvitesfunction = false
    public var invokedRemoveUserInvitesCount = 0
    public var invokedRemoveUserInvitesParameters: (userId: String, invites: [UserInvite])?
    public var invokedRemoveUserInvitesParametersList = [(userId: String, invites: [UserInvite])]()

    public func removeUserInvites(userId: String, invites: [UserInvite]) async throws {
        invokedRemoveUserInvitesfunction = true
        invokedRemoveUserInvitesCount += 1
        invokedRemoveUserInvitesParameters = (userId, invites)
        if let error = removeUserInvitesUserIdInvitesThrowableError3 {
            throw error
        }
        closureRemoveUserInvites()
    }
    // MARK: - removeAllUserInvites
    public var removeAllUserInvitesUserIdThrowableError4: Error?
    public var closureRemoveAllUserInvites: () -> () = {}
    public var invokedRemoveAllUserInvitesfunction = false
    public var invokedRemoveAllUserInvitesCount = 0
    public var invokedRemoveAllUserInvitesParameters: (userId: String, Void)?
    public var invokedRemoveAllUserInvitesParametersList = [(userId: String, Void)]()

    public func removeAllUserInvites(userId: String) async throws {
        invokedRemoveAllUserInvitesfunction = true
        invokedRemoveAllUserInvitesCount += 1
        invokedRemoveAllUserInvitesParameters = (userId, ())
        if let error = removeAllUserInvitesUserIdThrowableError4 {
            throw error
        }
        closureRemoveAllUserInvites()
    }
    // MARK: - getGroupInvites
    public var getGroupInvitesUserIdThrowableError5: Error?
    public var closureGetGroupInvites: () -> () = {}
    public var invokedGetGroupInvitesfunction = false
    public var invokedGetGroupInvitesCount = 0
    public var invokedGetGroupInvitesParameters: (userId: String, Void)?
    public var invokedGetGroupInvitesParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetGroupInvitesResult: [GroupInvite]!

    public func getGroupInvites(userId: String) async throws -> [GroupInvite] {
        invokedGetGroupInvitesfunction = true
        invokedGetGroupInvitesCount += 1
        invokedGetGroupInvitesParameters = (userId, ())
        if let error = getGroupInvitesUserIdThrowableError5 {
            throw error
        }
        closureGetGroupInvites()
        return stubbedGetGroupInvitesResult
    }
    // MARK: - upsertGroupInvites
    public var upsertGroupInvitesUserIdInvitesThrowableError6: Error?
    public var closureUpsertGroupInvites: () -> () = {}
    public var invokedUpsertGroupInvitesfunction = false
    public var invokedUpsertGroupInvitesCount = 0
    public var invokedUpsertGroupInvitesParameters: (userId: String, invites: [GroupInvite])?
    public var invokedUpsertGroupInvitesParametersList = [(userId: String, invites: [GroupInvite])]()

    public func upsertGroupInvites(userId: String, invites: [GroupInvite]) async throws {
        invokedUpsertGroupInvitesfunction = true
        invokedUpsertGroupInvitesCount += 1
        invokedUpsertGroupInvitesParameters = (userId, invites)
        if let error = upsertGroupInvitesUserIdInvitesThrowableError6 {
            throw error
        }
        closureUpsertGroupInvites()
    }
    // MARK: - removeGroupInvites
    public var removeGroupInvitesUserIdInvitesThrowableError7: Error?
    public var closureRemoveGroupInvites: () -> () = {}
    public var invokedRemoveGroupInvitesfunction = false
    public var invokedRemoveGroupInvitesCount = 0
    public var invokedRemoveGroupInvitesParameters: (userId: String, invites: [GroupInvite])?
    public var invokedRemoveGroupInvitesParametersList = [(userId: String, invites: [GroupInvite])]()

    public func removeGroupInvites(userId: String, invites: [GroupInvite]) async throws {
        invokedRemoveGroupInvitesfunction = true
        invokedRemoveGroupInvitesCount += 1
        invokedRemoveGroupInvitesParameters = (userId, invites)
        if let error = removeGroupInvitesUserIdInvitesThrowableError7 {
            throw error
        }
        closureRemoveGroupInvites()
    }
    // MARK: - removeAllGroupInvites
    public var removeAllGroupInvitesUserIdThrowableError8: Error?
    public var closureRemoveAllGroupInvites: () -> () = {}
    public var invokedRemoveAllGroupInvitesfunction = false
    public var invokedRemoveAllGroupInvitesCount = 0
    public var invokedRemoveAllGroupInvitesParameters: (userId: String, Void)?
    public var invokedRemoveAllGroupInvitesParametersList = [(userId: String, Void)]()

    public func removeAllGroupInvites(userId: String) async throws {
        invokedRemoveAllGroupInvitesfunction = true
        invokedRemoveAllGroupInvitesCount += 1
        invokedRemoveAllGroupInvitesParameters = (userId, ())
        if let error = removeAllGroupInvitesUserIdThrowableError8 {
            throw error
        }
        closureRemoveAllGroupInvites()
    }
}
