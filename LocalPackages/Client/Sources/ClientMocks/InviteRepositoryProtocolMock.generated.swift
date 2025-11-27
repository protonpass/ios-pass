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
    public var invokedCurrentPendingInvites: CurrentValueSubject<[Invite], Never>?
    public var invokedCurrentPendingInvitesList = [CurrentValueSubject<[Invite], Never>?]()
    public var invokedCurrentPendingInvitesGetter = false
    public var invokedCurrentPendingInvitesGetterCount = 0
    public var stubbedCurrentPendingInvites: CurrentValueSubject<[Invite], Never>!
    public var currentPendingInvites: CurrentValueSubject<[Invite], Never> {
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
    public var invokedAcceptInviteParameters: (invite: Invite, keys: [ItemKey])?
    public var invokedAcceptInviteParametersList = [(invite: Invite, keys: [ItemKey])]()
    public var stubbedAcceptInviteResult: Share?

    public func acceptInvite(_ invite: Invite, and keys: [ItemKey]) async throws -> Share? {
        invokedAcceptInvitefunction = true
        invokedAcceptInviteCount += 1
        invokedAcceptInviteParameters = (invite, keys)
        if let error = acceptInviteAndThrowableError2 {
            throw error
        }
        closureAcceptInvite()
        return stubbedAcceptInviteResult
    }
    // MARK: - rejectInvite
    public var rejectInviteThrowableError3: Error?
    public var closureRejectInvite: () -> () = {}
    public var invokedRejectInvitefunction = false
    public var invokedRejectInviteCount = 0
    public var invokedRejectInviteParameters: (invite: Invite, Void)?
    public var invokedRejectInviteParametersList = [(invite: Invite, Void)]()
    public var stubbedRejectInviteResult: Bool!

    public func rejectInvite(_ invite: Invite) async throws -> Bool {
        invokedRejectInvitefunction = true
        invokedRejectInviteCount += 1
        invokedRejectInviteParameters = (invite, ())
        if let error = rejectInviteThrowableError3 {
            throw error
        }
        closureRejectInvite()
        return stubbedRejectInviteResult
    }
    // MARK: - refreshAllInvites
    public var refreshAllInvitesUserIdThrowableError4: Error?
    public var closureRefreshAllInvites: () -> () = {}
    public var invokedRefreshAllInvitesfunction = false
    public var invokedRefreshAllInvitesCount = 0
    public var invokedRefreshAllInvitesParameters: (userId: String, Void)?
    public var invokedRefreshAllInvitesParametersList = [(userId: String, Void)]()

    public func refreshAllInvites(userId: String) async throws {
        invokedRefreshAllInvitesfunction = true
        invokedRefreshAllInvitesCount += 1
        invokedRefreshAllInvitesParameters = (userId, ())
        if let error = refreshAllInvitesUserIdThrowableError4 {
            throw error
        }
        closureRefreshAllInvites()
    }
    // MARK: - refreshSpecificInvites
    public var refreshSpecificInvitesUserIdRefreshInviteTypeThrowableError5: Error?
    public var closureRefreshSpecificInvites: () -> () = {}
    public var invokedRefreshSpecificInvitesfunction = false
    public var invokedRefreshSpecificInvitesCount = 0
    public var invokedRefreshSpecificInvitesParameters: (userId: String, refreshInviteType: RefreshInviteType)?
    public var invokedRefreshSpecificInvitesParametersList = [(userId: String, refreshInviteType: RefreshInviteType)]()

    public func refreshSpecificInvites(userId: String, refreshInviteType: RefreshInviteType) async throws {
        invokedRefreshSpecificInvitesfunction = true
        invokedRefreshSpecificInvitesCount += 1
        invokedRefreshSpecificInvitesParameters = (userId, refreshInviteType)
        if let error = refreshSpecificInvitesUserIdRefreshInviteTypeThrowableError5 {
            throw error
        }
        closureRefreshSpecificInvites()
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
        closureRemoveCachedInvite()
    }
    // MARK: - sendNewShareInvites
    public var sendNewShareInvitesShareIdNewShareInviteThrowableError7: Error?
    public var closureSendNewShareInvites: () -> () = {}
    public var invokedSendNewShareInvitesfunction = false
    public var invokedSendNewShareInvitesCount = 0
    public var invokedSendNewShareInvitesParameters: (shareId: String, newShareInvite: [ShareNewUserInvite])?
    public var invokedSendNewShareInvitesParametersList = [(shareId: String, newShareInvite: [ShareNewUserInvite])]()

    public func sendNewShareInvites(shareId: String, newShareInvite: [ShareNewUserInvite]) async throws {
        invokedSendNewShareInvitesfunction = true
        invokedSendNewShareInvitesCount += 1
        invokedSendNewShareInvitesParameters = (shareId, newShareInvite)
        if let error = sendNewShareInvitesShareIdNewShareInviteThrowableError7 {
            throw error
        }
        closureSendNewShareInvites()
    }
}
