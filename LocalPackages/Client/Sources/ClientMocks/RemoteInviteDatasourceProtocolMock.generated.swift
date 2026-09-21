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
import Entities

public final class RemoteInviteDatasourceProtocolMock: @unchecked Sendable, RemoteInviteDatasourceProtocol {

    public init() {}

    // MARK: - getPendingInvitesForUser
    public var getPendingInvitesForUserUserIdEventTokenThrowableError1: Error?
    public var closureGetPendingInvitesForUser: () -> () = {}
    public var invokedGetPendingInvitesForUserfunction = false
    public var invokedGetPendingInvitesForUserCount = 0
    public var invokedGetPendingInvitesForUserParameters: (userId: String, eventToken: String?)?
    public var invokedGetPendingInvitesForUserParametersList = [(userId: String, eventToken: String?)]()
    public nonisolated(unsafe) var stubbedGetPendingInvitesForUserResult: [UserInvite]!

    public func getPendingInvitesForUser(userId: String, eventToken: String?) async throws -> [UserInvite] {
        invokedGetPendingInvitesForUserfunction = true
        invokedGetPendingInvitesForUserCount += 1
        invokedGetPendingInvitesForUserParameters = (userId, eventToken)
        if let error = getPendingInvitesForUserUserIdEventTokenThrowableError1 {
            throw error
        }
        closureGetPendingInvitesForUser()
        return stubbedGetPendingInvitesForUserResult
    }
    // MARK: - acceptInvite
    public var acceptInviteUserIdInviteTokenRequestThrowableError2: Error?
    public var closureAcceptInvite: () -> () = {}
    public var invokedAcceptInvitefunction = false
    public var invokedAcceptInviteCount = 0
    public var invokedAcceptInviteParameters: (userId: String, inviteToken: String, request: AcceptInviteRequest)?
    public var invokedAcceptInviteParametersList = [(userId: String, inviteToken: String, request: AcceptInviteRequest)]()
    public nonisolated(unsafe) var stubbedAcceptInviteResult: Share!

    public func acceptInvite(userId: String, inviteToken: String, request: AcceptInviteRequest) async throws -> Share {
        invokedAcceptInvitefunction = true
        invokedAcceptInviteCount += 1
        invokedAcceptInviteParameters = (userId, inviteToken, request)
        if let error = acceptInviteUserIdInviteTokenRequestThrowableError2 {
            throw error
        }
        closureAcceptInvite()
        return stubbedAcceptInviteResult
    }
    // MARK: - rejectInvite
    public var rejectInviteUserIdInviteTokenThrowableError3: Error?
    public var closureRejectInvite: () -> () = {}
    public var invokedRejectInvitefunction = false
    public var invokedRejectInviteCount = 0
    public var invokedRejectInviteParameters: (userId: String, inviteToken: String)?
    public var invokedRejectInviteParametersList = [(userId: String, inviteToken: String)]()
    public nonisolated(unsafe) var stubbedRejectInviteResult: Bool!

    public func rejectInvite(userId: String, inviteToken: String) async throws -> Bool {
        invokedRejectInvitefunction = true
        invokedRejectInviteCount += 1
        invokedRejectInviteParameters = (userId, inviteToken)
        if let error = rejectInviteUserIdInviteTokenThrowableError3 {
            throw error
        }
        closureRejectInvite()
        return stubbedRejectInviteResult
    }
    // MARK: - getPendingInvites
    public var getPendingInvitesUserIdSharedIdThrowableError4: Error?
    public var closureGetPendingInvites: () -> () = {}
    public var invokedGetPendingInvitesfunction = false
    public var invokedGetPendingInvitesCount = 0
    public var invokedGetPendingInvitesParameters: (userId: String, sharedId: String)?
    public var invokedGetPendingInvitesParametersList = [(userId: String, sharedId: String)]()
    public nonisolated(unsafe) var stubbedGetPendingInvitesResult: ShareInvites!

    public func getPendingInvites(userId: String, sharedId: String) async throws -> ShareInvites {
        invokedGetPendingInvitesfunction = true
        invokedGetPendingInvitesCount += 1
        invokedGetPendingInvitesParameters = (userId, sharedId)
        if let error = getPendingInvitesUserIdSharedIdThrowableError4 {
            throw error
        }
        closureGetPendingInvites()
        return stubbedGetPendingInvitesResult
    }
    // MARK: - inviteExistingUsers
    public var inviteExistingUsersUserIdShareIdRequestThrowableError5: Error?
    public var closureInviteExistingUsers: () -> () = {}
    public var invokedInviteExistingUsersfunction = false
    public var invokedInviteExistingUsersCount = 0
    public var invokedInviteExistingUsersParameters: (userId: String, shareId: String, request: InviteMultipleUsersToShareRequest)?
    public var invokedInviteExistingUsersParametersList = [(userId: String, shareId: String, request: InviteMultipleUsersToShareRequest)]()
    public nonisolated(unsafe) var stubbedInviteExistingUsersResult: Bool!

    public func inviteExistingUsers(userId: String, shareId: String, request: InviteMultipleUsersToShareRequest) async throws -> Bool {
        invokedInviteExistingUsersfunction = true
        invokedInviteExistingUsersCount += 1
        invokedInviteExistingUsersParameters = (userId, shareId, request)
        if let error = inviteExistingUsersUserIdShareIdRequestThrowableError5 {
            throw error
        }
        closureInviteExistingUsers()
        return stubbedInviteExistingUsersResult
    }
    // MARK: - inviteNewUsers
    public var inviteNewUsersUserIdShareIdRequestThrowableError6: Error?
    public var closureInviteNewUsers: () -> () = {}
    public var invokedInviteNewUsersfunction = false
    public var invokedInviteNewUsersCount = 0
    public var invokedInviteNewUsersParameters: (userId: String, shareId: String, request: InviteMultipleNewUsersToShareRequest)?
    public var invokedInviteNewUsersParametersList = [(userId: String, shareId: String, request: InviteMultipleNewUsersToShareRequest)]()
    public nonisolated(unsafe) var stubbedInviteNewUsersResult: Bool!

    public func inviteNewUsers(userId: String, shareId: String, request: InviteMultipleNewUsersToShareRequest) async throws -> Bool {
        invokedInviteNewUsersfunction = true
        invokedInviteNewUsersCount += 1
        invokedInviteNewUsersParameters = (userId, shareId, request)
        if let error = inviteNewUsersUserIdShareIdRequestThrowableError6 {
            throw error
        }
        closureInviteNewUsers()
        return stubbedInviteNewUsersResult
    }
    // MARK: - promoteNewUserInvite
    public var promoteNewUserInviteUserIdShareIdInviteIdKeysThrowableError7: Error?
    public var closurePromoteNewUserInvite: () -> () = {}
    public var invokedPromoteNewUserInvitefunction = false
    public var invokedPromoteNewUserInviteCount = 0
    public var invokedPromoteNewUserInviteParameters: (userId: String, shareId: String, inviteId: String, keys: [ItemKey])?
    public var invokedPromoteNewUserInviteParametersList = [(userId: String, shareId: String, inviteId: String, keys: [ItemKey])]()
    public nonisolated(unsafe) var stubbedPromoteNewUserInviteResult: Bool!

    public func promoteNewUserInvite(userId: String, shareId: String, inviteId: String, keys: [ItemKey]) async throws -> Bool {
        invokedPromoteNewUserInvitefunction = true
        invokedPromoteNewUserInviteCount += 1
        invokedPromoteNewUserInviteParameters = (userId, shareId, inviteId, keys)
        if let error = promoteNewUserInviteUserIdShareIdInviteIdKeysThrowableError7 {
            throw error
        }
        closurePromoteNewUserInvite()
        return stubbedPromoteNewUserInviteResult
    }
    // MARK: - sendInviteReminder
    public var sendInviteReminderUserIdShareIdInviteIdThrowableError8: Error?
    public var closureSendInviteReminder: () -> () = {}
    public var invokedSendInviteReminderfunction = false
    public var invokedSendInviteReminderCount = 0
    public var invokedSendInviteReminderParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedSendInviteReminderParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public nonisolated(unsafe) var stubbedSendInviteReminderResult: Bool!

    public func sendInviteReminder(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedSendInviteReminderfunction = true
        invokedSendInviteReminderCount += 1
        invokedSendInviteReminderParameters = (userId, shareId, inviteId)
        if let error = sendInviteReminderUserIdShareIdInviteIdThrowableError8 {
            throw error
        }
        closureSendInviteReminder()
        return stubbedSendInviteReminderResult
    }
    // MARK: - deleteShareInvite
    public var deleteShareInviteUserIdShareIdInviteIdThrowableError9: Error?
    public var closureDeleteShareInvite: () -> () = {}
    public var invokedDeleteShareInvitefunction = false
    public var invokedDeleteShareInviteCount = 0
    public var invokedDeleteShareInviteParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedDeleteShareInviteParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public nonisolated(unsafe) var stubbedDeleteShareInviteResult: Bool!

    public func deleteShareInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteShareInvitefunction = true
        invokedDeleteShareInviteCount += 1
        invokedDeleteShareInviteParameters = (userId, shareId, inviteId)
        if let error = deleteShareInviteUserIdShareIdInviteIdThrowableError9 {
            throw error
        }
        closureDeleteShareInvite()
        return stubbedDeleteShareInviteResult
    }
    // MARK: - deleteShareNewUserInvite
    public var deleteShareNewUserInviteUserIdShareIdInviteIdThrowableError10: Error?
    public var closureDeleteShareNewUserInvite: () -> () = {}
    public var invokedDeleteShareNewUserInvitefunction = false
    public var invokedDeleteShareNewUserInviteCount = 0
    public var invokedDeleteShareNewUserInviteParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedDeleteShareNewUserInviteParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public nonisolated(unsafe) var stubbedDeleteShareNewUserInviteResult: Bool!

    public func deleteShareNewUserInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteShareNewUserInvitefunction = true
        invokedDeleteShareNewUserInviteCount += 1
        invokedDeleteShareNewUserInviteParameters = (userId, shareId, inviteId)
        if let error = deleteShareNewUserInviteUserIdShareIdInviteIdThrowableError10 {
            throw error
        }
        closureDeleteShareNewUserInvite()
        return stubbedDeleteShareNewUserInviteResult
    }
    // MARK: - getInviteRecommendations
    public var getInviteRecommendationsUserIdShareIdQueryThrowableError11: Error?
    public var closureGetInviteRecommendations: () -> () = {}
    public var invokedGetInviteRecommendationsfunction = false
    public var invokedGetInviteRecommendationsCount = 0
    public var invokedGetInviteRecommendationsParameters: (userId: String, shareId: String, query: InviteRecommendationsQuery)?
    public var invokedGetInviteRecommendationsParametersList = [(userId: String, shareId: String, query: InviteRecommendationsQuery)]()
    public nonisolated(unsafe) var stubbedGetInviteRecommendationsResult: InviteRecommendations!

    public func getInviteRecommendations(userId: String, shareId: String, query: InviteRecommendationsQuery) async throws -> InviteRecommendations {
        invokedGetInviteRecommendationsfunction = true
        invokedGetInviteRecommendationsCount += 1
        invokedGetInviteRecommendationsParameters = (userId, shareId, query)
        if let error = getInviteRecommendationsUserIdShareIdQueryThrowableError11 {
            throw error
        }
        closureGetInviteRecommendations()
        return stubbedGetInviteRecommendationsResult
    }
    // MARK: - getInviteSuggestions
    public var getInviteSuggestionsUserIdShareIdEmailThrowableError12: Error?
    public var closureGetInviteSuggestions: () -> () = {}
    public var invokedGetInviteSuggestionsfunction = false
    public var invokedGetInviteSuggestionsCount = 0
    public var invokedGetInviteSuggestionsParameters: (userId: String, shareId: String, email: String?)?
    public var invokedGetInviteSuggestionsParametersList = [(userId: String, shareId: String, email: String?)]()
    public nonisolated(unsafe) var stubbedGetInviteSuggestionsResult: [InviteSuggestion]!

    public func getInviteSuggestions(userId: String, shareId: String, email: String?) async throws -> [InviteSuggestion] {
        invokedGetInviteSuggestionsfunction = true
        invokedGetInviteSuggestionsCount += 1
        invokedGetInviteSuggestionsParameters = (userId, shareId, email)
        if let error = getInviteSuggestionsUserIdShareIdEmailThrowableError12 {
            throw error
        }
        closureGetInviteSuggestions()
        return stubbedGetInviteSuggestionsResult
    }
    // MARK: - getOrganizationRecommendations
    public var getOrganizationRecommendationsUserIdShareIdQueryThrowableError13: Error?
    public var closureGetOrganizationRecommendations: () -> () = {}
    public var invokedGetOrganizationRecommendationsfunction = false
    public var invokedGetOrganizationRecommendationsCount = 0
    public var invokedGetOrganizationRecommendationsParameters: (userId: String, shareId: String, query: InviteRecommendationsQuery)?
    public var invokedGetOrganizationRecommendationsParametersList = [(userId: String, shareId: String, query: InviteRecommendationsQuery)]()
    public nonisolated(unsafe) var stubbedGetOrganizationRecommendationsResult: OrganizationInviteRecommendations!

    public func getOrganizationRecommendations(userId: String, shareId: String, query: InviteRecommendationsQuery) async throws -> OrganizationInviteRecommendations {
        invokedGetOrganizationRecommendationsfunction = true
        invokedGetOrganizationRecommendationsCount += 1
        invokedGetOrganizationRecommendationsParameters = (userId, shareId, query)
        if let error = getOrganizationRecommendationsUserIdShareIdQueryThrowableError13 {
            throw error
        }
        closureGetOrganizationRecommendations()
        return stubbedGetOrganizationRecommendationsResult
    }
    // MARK: - checkAddresses
    public var checkAddressesUserIdShareIdEmailsThrowableError14: Error?
    public var closureCheckAddresses: () -> () = {}
    public var invokedCheckAddressesfunction = false
    public var invokedCheckAddressesCount = 0
    public var invokedCheckAddressesParameters: (userId: String, shareId: String, emails: [String])?
    public var invokedCheckAddressesParametersList = [(userId: String, shareId: String, emails: [String])]()
    public nonisolated(unsafe) var stubbedCheckAddressesResult: [String]!

    public func checkAddresses(userId: String, shareId: String, emails: [String]) async throws -> [String] {
        invokedCheckAddressesfunction = true
        invokedCheckAddressesCount += 1
        invokedCheckAddressesParameters = (userId, shareId, emails)
        if let error = checkAddressesUserIdShareIdEmailsThrowableError14 {
            throw error
        }
        closureCheckAddresses()
        return stubbedCheckAddressesResult
    }
    // MARK: - getPendingGroupInvitesForUser
    public var getPendingGroupInvitesForUserLastTokenUserIdEventTokenThrowableError15: Error?
    public var closureGetPendingGroupInvitesForUser: () -> () = {}
    public var invokedGetPendingGroupInvitesForUserfunction = false
    public var invokedGetPendingGroupInvitesForUserCount = 0
    public var invokedGetPendingGroupInvitesForUserParameters: (lastToken: String?, userId: String, eventToken: String?)?
    public var invokedGetPendingGroupInvitesForUserParametersList = [(lastToken: String?, userId: String, eventToken: String?)]()
    public nonisolated(unsafe) var stubbedGetPendingGroupInvitesForUserResult: PaginatedGroupInvites!

    public func getPendingGroupInvitesForUser(lastToken: String?, userId: String, eventToken: String?) async throws -> PaginatedGroupInvites {
        invokedGetPendingGroupInvitesForUserfunction = true
        invokedGetPendingGroupInvitesForUserCount += 1
        invokedGetPendingGroupInvitesForUserParameters = (lastToken, userId, eventToken)
        if let error = getPendingGroupInvitesForUserLastTokenUserIdEventTokenThrowableError15 {
            throw error
        }
        closureGetPendingGroupInvitesForUser()
        return stubbedGetPendingGroupInvitesForUserResult
    }
    // MARK: - acceptGroupInvite
    public var acceptGroupInviteUserIdInviteTokenRequestThrowableError16: Error?
    public var closureAcceptGroupInvite: () -> () = {}
    public var invokedAcceptGroupInvitefunction = false
    public var invokedAcceptGroupInviteCount = 0
    public var invokedAcceptGroupInviteParameters: (userId: String, inviteToken: String, request: AcceptInviteRequest)?
    public var invokedAcceptGroupInviteParametersList = [(userId: String, inviteToken: String, request: AcceptInviteRequest)]()

    public func acceptGroupInvite(userId: String, inviteToken: String, request: AcceptInviteRequest) async throws {
        invokedAcceptGroupInvitefunction = true
        invokedAcceptGroupInviteCount += 1
        invokedAcceptGroupInviteParameters = (userId, inviteToken, request)
        if let error = acceptGroupInviteUserIdInviteTokenRequestThrowableError16 {
            throw error
        }
        closureAcceptGroupInvite()
    }
    // MARK: - rejectGroupInvite
    public var rejectGroupInviteUserIdInviteTokenThrowableError17: Error?
    public var closureRejectGroupInvite: () -> () = {}
    public var invokedRejectGroupInvitefunction = false
    public var invokedRejectGroupInviteCount = 0
    public var invokedRejectGroupInviteParameters: (userId: String, inviteToken: String)?
    public var invokedRejectGroupInviteParametersList = [(userId: String, inviteToken: String)]()
    public nonisolated(unsafe) var stubbedRejectGroupInviteResult: Bool!

    public func rejectGroupInvite(userId: String, inviteToken: String) async throws -> Bool {
        invokedRejectGroupInvitefunction = true
        invokedRejectGroupInviteCount += 1
        invokedRejectGroupInviteParameters = (userId, inviteToken)
        if let error = rejectGroupInviteUserIdInviteTokenThrowableError17 {
            throw error
        }
        closureRejectGroupInvite()
        return stubbedRejectGroupInviteResult
    }
}
