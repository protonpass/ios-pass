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

public final class ShareInviteRepositoryProtocolMock: @unchecked Sendable, ShareInviteRepositoryProtocol {

    public init() {}

    // MARK: - getAllPendingInvites
    public var getAllPendingInvitesUserIdShareIdThrowableError1: Error?
    public var closureGetAllPendingInvites: () -> () = {}
    public var invokedGetAllPendingInvitesfunction = false
    public var invokedGetAllPendingInvitesCount = 0
    public var invokedGetAllPendingInvitesParameters: (userId: String, shareId: String)?
    public var invokedGetAllPendingInvitesParametersList = [(userId: String, shareId: String)]()
    public var stubbedGetAllPendingInvitesResult: ShareInvites!

    public func getAllPendingInvites(userId: String, shareId: String) async throws -> ShareInvites {
        invokedGetAllPendingInvitesfunction = true
        invokedGetAllPendingInvitesCount += 1
        invokedGetAllPendingInvitesParameters = (userId, shareId)
        if let error = getAllPendingInvitesUserIdShareIdThrowableError1 {
            throw error
        }
        closureGetAllPendingInvites()
        return stubbedGetAllPendingInvitesResult
    }
    // MARK: - sendInvites
    public var sendInvitesUserIdShareIdItemIdInviteesDataTargetTypeThrowableError2: Error?
    public var closureSendInvites: () -> () = {}
    public var invokedSendInvitesfunction = false
    public var invokedSendInvitesCount = 0
    public var invokedSendInvitesParameters: (userId: String, shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType)?
    public var invokedSendInvitesParametersList = [(userId: String, shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType)]()
    public var stubbedSendInvitesResult: Bool!

    public func sendInvites(userId: String, shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType) async throws -> Bool {
        invokedSendInvitesfunction = true
        invokedSendInvitesCount += 1
        invokedSendInvitesParameters = (userId, shareId, itemId, inviteesData, targetType)
        if let error = sendInvitesUserIdShareIdItemIdInviteesDataTargetTypeThrowableError2 {
            throw error
        }
        closureSendInvites()
        return stubbedSendInvitesResult
    }
    // MARK: - promoteNewUserInvite
    public var promoteNewUserInviteUserIdShareIdInviteIdKeysThrowableError3: Error?
    public var closurePromoteNewUserInvite: () -> () = {}
    public var invokedPromoteNewUserInvitefunction = false
    public var invokedPromoteNewUserInviteCount = 0
    public var invokedPromoteNewUserInviteParameters: (userId: String, shareId: String, inviteId: String, keys: [ItemKey])?
    public var invokedPromoteNewUserInviteParametersList = [(userId: String, shareId: String, inviteId: String, keys: [ItemKey])]()
    public var stubbedPromoteNewUserInviteResult: Bool!

    public func promoteNewUserInvite(userId: String, shareId: String, inviteId: String, keys: [ItemKey]) async throws -> Bool {
        invokedPromoteNewUserInvitefunction = true
        invokedPromoteNewUserInviteCount += 1
        invokedPromoteNewUserInviteParameters = (userId, shareId, inviteId, keys)
        if let error = promoteNewUserInviteUserIdShareIdInviteIdKeysThrowableError3 {
            throw error
        }
        closurePromoteNewUserInvite()
        return stubbedPromoteNewUserInviteResult
    }
    // MARK: - sendInviteReminder
    public var sendInviteReminderUserIdShareIdInviteIdThrowableError4: Error?
    public var closureSendInviteReminder: () -> () = {}
    public var invokedSendInviteReminderfunction = false
    public var invokedSendInviteReminderCount = 0
    public var invokedSendInviteReminderParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedSendInviteReminderParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public var stubbedSendInviteReminderResult: Bool!

    public func sendInviteReminder(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedSendInviteReminderfunction = true
        invokedSendInviteReminderCount += 1
        invokedSendInviteReminderParameters = (userId, shareId, inviteId)
        if let error = sendInviteReminderUserIdShareIdInviteIdThrowableError4 {
            throw error
        }
        closureSendInviteReminder()
        return stubbedSendInviteReminderResult
    }
    // MARK: - deleteInvite
    public var deleteInviteUserIdShareIdInviteIdThrowableError5: Error?
    public var closureDeleteInvite: () -> () = {}
    public var invokedDeleteInvitefunction = false
    public var invokedDeleteInviteCount = 0
    public var invokedDeleteInviteParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedDeleteInviteParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public var stubbedDeleteInviteResult: Bool!

    public func deleteInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteInvitefunction = true
        invokedDeleteInviteCount += 1
        invokedDeleteInviteParameters = (userId, shareId, inviteId)
        if let error = deleteInviteUserIdShareIdInviteIdThrowableError5 {
            throw error
        }
        closureDeleteInvite()
        return stubbedDeleteInviteResult
    }
    // MARK: - deleteNewUserInvite
    public var deleteNewUserInviteUserIdShareIdInviteIdThrowableError6: Error?
    public var closureDeleteNewUserInvite: () -> () = {}
    public var invokedDeleteNewUserInvitefunction = false
    public var invokedDeleteNewUserInviteCount = 0
    public var invokedDeleteNewUserInviteParameters: (userId: String, shareId: String, inviteId: String)?
    public var invokedDeleteNewUserInviteParametersList = [(userId: String, shareId: String, inviteId: String)]()
    public var stubbedDeleteNewUserInviteResult: Bool!

    public func deleteNewUserInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteNewUserInvitefunction = true
        invokedDeleteNewUserInviteCount += 1
        invokedDeleteNewUserInviteParameters = (userId, shareId, inviteId)
        if let error = deleteNewUserInviteUserIdShareIdInviteIdThrowableError6 {
            throw error
        }
        closureDeleteNewUserInvite()
        return stubbedDeleteNewUserInviteResult
    }
    // MARK: - getInviteRecommendations
    public var getInviteRecommendationsUserIdShareIdQueryThrowableError7: Error?
    public var closureGetInviteRecommendations: () -> () = {}
    public var invokedGetInviteRecommendationsfunction = false
    public var invokedGetInviteRecommendationsCount = 0
    public var invokedGetInviteRecommendationsParameters: (userId: String, shareId: String, query: InviteRecommendationsQuery)?
    public var invokedGetInviteRecommendationsParametersList = [(userId: String, shareId: String, query: InviteRecommendationsQuery)]()
    public var stubbedGetInviteRecommendationsResult: InviteRecommendations!

    public func getInviteRecommendations(userId: String, shareId: String, query: InviteRecommendationsQuery) async throws -> InviteRecommendations {
        invokedGetInviteRecommendationsfunction = true
        invokedGetInviteRecommendationsCount += 1
        invokedGetInviteRecommendationsParameters = (userId, shareId, query)
        if let error = getInviteRecommendationsUserIdShareIdQueryThrowableError7 {
            throw error
        }
        closureGetInviteRecommendations()
        return stubbedGetInviteRecommendationsResult
    }
    // MARK: - getSuggestedInvite
    public var getSuggestedInviteUserIdShareIdEmailThrowableError8: Error?
    public var closureGetSuggestedInvite: () -> () = {}
    public var invokedGetSuggestedInvitefunction = false
    public var invokedGetSuggestedInviteCount = 0
    public var invokedGetSuggestedInviteParameters: (userId: String, shareId: String, email: String?)?
    public var invokedGetSuggestedInviteParametersList = [(userId: String, shareId: String, email: String?)]()
    public var stubbedGetSuggestedInviteResult: [InviteSuggestion]!

    public func getSuggestedInvite(userId: String, shareId: String, email: String?) async throws -> [InviteSuggestion] {
        invokedGetSuggestedInvitefunction = true
        invokedGetSuggestedInviteCount += 1
        invokedGetSuggestedInviteParameters = (userId, shareId, email)
        if let error = getSuggestedInviteUserIdShareIdEmailThrowableError8 {
            throw error
        }
        closureGetSuggestedInvite()
        return stubbedGetSuggestedInviteResult
    }
    // MARK: - getOrganisationInviteRecommendations
    public var getOrganisationInviteRecommendationsUserIdShareIdQueryThrowableError9: Error?
    public var closureGetOrganisationInviteRecommendations: () -> () = {}
    public var invokedGetOrganisationInviteRecommendationsfunction = false
    public var invokedGetOrganisationInviteRecommendationsCount = 0
    public var invokedGetOrganisationInviteRecommendationsParameters: (userId: String, shareId: String, query: InviteRecommendationsQuery)?
    public var invokedGetOrganisationInviteRecommendationsParametersList = [(userId: String, shareId: String, query: InviteRecommendationsQuery)]()
    public var stubbedGetOrganisationInviteRecommendationsResult: OrganizationInviteRecommendations!

    public func getOrganisationInviteRecommendations(userId: String, shareId: String, query: InviteRecommendationsQuery) async throws -> OrganizationInviteRecommendations {
        invokedGetOrganisationInviteRecommendationsfunction = true
        invokedGetOrganisationInviteRecommendationsCount += 1
        invokedGetOrganisationInviteRecommendationsParameters = (userId, shareId, query)
        if let error = getOrganisationInviteRecommendationsUserIdShareIdQueryThrowableError9 {
            throw error
        }
        closureGetOrganisationInviteRecommendations()
        return stubbedGetOrganisationInviteRecommendationsResult
    }
    // MARK: - checkAddresses
    public var checkAddressesUserIdShareIdEmailsThrowableError10: Error?
    public var closureCheckAddresses: () -> () = {}
    public var invokedCheckAddressesfunction = false
    public var invokedCheckAddressesCount = 0
    public var invokedCheckAddressesParameters: (userId: String, shareId: String, emails: [String])?
    public var invokedCheckAddressesParametersList = [(userId: String, shareId: String, emails: [String])]()
    public var stubbedCheckAddressesResult: [String]!

    public func checkAddresses(userId: String, shareId: String, emails: [String]) async throws -> [String] {
        invokedCheckAddressesfunction = true
        invokedCheckAddressesCount += 1
        invokedCheckAddressesParameters = (userId, shareId, emails)
        if let error = checkAddressesUserIdShareIdEmailsThrowableError10 {
            throw error
        }
        closureCheckAddresses()
        return stubbedCheckAddressesResult
    }
}
