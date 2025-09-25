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
import Combine
import Core
import Entities
import Foundation
import ProtonCoreLogin

public final class InviteRepositoryProtocolMock: @unchecked Sendable, InviteRepositoryProtocol {

    public init() {}

    // MARK: - currentPendingInvites
    public var invokedCurrentPendingInvitesSetter = false
    public var invokedCurrentPendingInvitesSetterCount = 0
    public var invokedCurrentPendingInvites: CurrentValueSubject<[InviteType], Never>?
    public var invokedCurrentPendingInvitesList = [CurrentValueSubject<[InviteType], Never>?]()
    public var invokedCurrentPendingInvitesGetter = false
    public var invokedCurrentPendingInvitesGetterCount = 0
    public var stubbedCurrentPendingInvites: CurrentValueSubject<[InviteType], Never>!
    public var currentPendingInvites: CurrentValueSubject<[InviteType], Never> {
        set {
            invokedCurrentPendingInvitesSetter = true
            invokedCurrentPendingInvitesSetterCount += 1
            invokedCurrentPendingInvites = newValue
            invokedCurrentPendingInvitesList.append(newValue)
        } get {
            invokedCurrentPendingInvitesGetter = true
            invokedCurrentPendingInvitesGetterCount += 1
            return stubbedCurrentPendingInvites
        }
    }
    // MARK: - loadLocalInvites
    public var loadLocalInvitesUserIdThrowableError1: Error?
    public var closureLoadLocalInvites: () -> () = {}
    public var invokedLoadLocalInvitesfunction = false
    public var invokedLoadLocalInvitesCount = 0
    public var invokedLoadLocalInvitesParameters: (userId: String, Void)?
    public var invokedLoadLocalInvitesParametersList = [(userId: String, Void)]()

    public func loadLocalInvites(userId: String) async throws {
        invokedLoadLocalInvitesfunction = true
        invokedLoadLocalInvitesCount += 1
        invokedLoadLocalInvitesParameters = (userId, ())
        invokedLoadLocalInvitesParametersList.append((userId, ()))
        if let error = loadLocalInvitesUserIdThrowableError1 {
            throw error
        }
        closureLoadLocalInvites()
    }
    // MARK: - acceptInvite
    public var acceptInviteAndThrowableError2: Error?
    public var closureAcceptInvite: () -> () = {}
    public var invokedAcceptInvitefunction = false
    public var invokedAcceptInviteCount = 0
    public var invokedAcceptInviteParameters: (invite: UserInvite, keys: [ItemKey])?
    public var invokedAcceptInviteParametersList = [(invite: UserInvite, keys: [ItemKey])]()
    public var stubbedAcceptInviteResult: Share!

    public func acceptInvite(_ invite: UserInvite, and keys: [ItemKey]) async throws -> Share {
        invokedAcceptInvitefunction = true
        invokedAcceptInviteCount += 1
        invokedAcceptInviteParameters = (invite, keys)
        invokedAcceptInviteParametersList.append((invite, keys))
        if let error = acceptInviteAndThrowableError2 {
            throw error
        }
        closureAcceptInvite()
        return stubbedAcceptInviteResult
    }
    // MARK: - acceptGroupInvite
    public var acceptGroupInviteWithAndThrowableError3: Error?
    public var closureAcceptGroupInvite: () -> () = {}
    public var invokedAcceptGroupInvitefunction = false
    public var invokedAcceptGroupInviteCount = 0
    public var invokedAcceptGroupInviteParameters: (inviteToken: String, keys: [ItemKey])?
    public var invokedAcceptGroupInviteParametersList = [(inviteToken: String, keys: [ItemKey])]()

    public func acceptGroupInvite(with inviteToken: String, and keys: [ItemKey]) async throws {
        invokedAcceptGroupInvitefunction = true
        invokedAcceptGroupInviteCount += 1
        invokedAcceptGroupInviteParameters = (inviteToken, keys)
        invokedAcceptGroupInviteParametersList.append((inviteToken, keys))
        if let error = acceptGroupInviteWithAndThrowableError3 {
            throw error
        }
        closureAcceptGroupInvite()
    }
    // MARK: - rejectInvite
    public var rejectInviteThrowableError4: Error?
    public var closureRejectInvite: () -> () = {}
    public var invokedRejectInvitefunction = false
    public var invokedRejectInviteCount = 0
    public var invokedRejectInviteParameters: (invite: UserInvite, Void)?
    public var invokedRejectInviteParametersList = [(invite: UserInvite, Void)]()
    public var stubbedRejectInviteResult: Bool!

    public func rejectInvite(_ invite: UserInvite) async throws -> Bool {
        invokedRejectInvitefunction = true
        invokedRejectInviteCount += 1
        invokedRejectInviteParameters = (invite, ())
        invokedRejectInviteParametersList.append((invite, ()))
        if let error = rejectInviteThrowableError4 {
            throw error
        }
        closureRejectInvite()
        return stubbedRejectInviteResult
    }
    // MARK: - refreshInvites
    public var refreshInvitesUserIdThrowableError5: Error?
    public var closureRefreshInvites: () -> () = {}
    public var invokedRefreshInvitesfunction = false
    public var invokedRefreshInvitesCount = 0
    public var invokedRefreshInvitesParameters: (userId: String, Void)?
    public var invokedRefreshInvitesParametersList = [(userId: String, Void)]()

    public func refreshInvites(userId: String) async throws {
        invokedRefreshInvitesfunction = true
        invokedRefreshInvitesCount += 1
        invokedRefreshInvitesParameters = (userId, ())
        invokedRefreshInvitesParametersList.append((userId, ()))
        if let error = refreshInvitesUserIdThrowableError5 {
            throw error
        }
        closureRefreshInvites()
    }
    // MARK: - removeCachedInvite
    public var closureRemoveCachedInvite: () -> () = {}
    public var invokedRemoveCachedInvitefunction = false
    public var invokedRemoveCachedInviteCount = 0
    public var invokedRemoveCachedInviteParameters: (inviteToken: String, Void)?
    public var invokedRemoveCachedInviteParametersList = [(inviteToken: String, Void)]()

    public func removeCachedInvite(containing inviteToken: String) async {
        invokedRemoveCachedInvitefunction = true
        invokedRemoveCachedInviteCount += 1
        invokedRemoveCachedInviteParameters = (inviteToken, ())
        invokedRemoveCachedInviteParametersList.append((inviteToken, ()))
        closureRemoveCachedInvite()
    }
}
