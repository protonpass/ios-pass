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

public final class FullInviteRepositoryProtocolMock: @unchecked Sendable, InviteRepositoryProtocol, ShareInviteRepositoryProtocol {

    public init() {}

    // MARK: - ⚡️ InviteRepositoryProtocol
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
    public var acceptInviteUserIdInviteKeysThrowableError2: Error?
    public var closureAcceptInvite: () -> () = {}
    public var invokedAcceptInvitefunction = false
    public var invokedAcceptInviteCount = 0
    public var invokedAcceptInviteParameters: (userId: String, invite: Invite, keys: [ItemKey])?
    public var invokedAcceptInviteParametersList = [(userId: String, invite: Invite, keys: [ItemKey])]()
    public var stubbedAcceptInviteResult: Share?

    public func acceptInvite(userId: String, invite: Invite, keys: [ItemKey]) async throws -> Share? {
        invokedAcceptInvitefunction = true
        invokedAcceptInviteCount += 1
        invokedAcceptInviteParameters = (userId, invite, keys)
        if let error = acceptInviteUserIdInviteKeysThrowableError2 {
            throw error
        }
        closureAcceptInvite()
        return stubbedAcceptInviteResult
    }
    // MARK: - rejectInvite
    public var rejectInviteUserIdInviteThrowableError3: Error?
    public var closureRejectInvite: () -> () = {}
    public var invokedRejectInvitefunction = false
    public var invokedRejectInviteCount = 0
    public var invokedRejectInviteParameters: (userId: String, invite: Invite)?
    public var invokedRejectInviteParametersList = [(userId: String, invite: Invite)]()
    public var stubbedRejectInviteResult: Bool!

    public func rejectInvite(userId: String, invite: Invite) async throws -> Bool {
        invokedRejectInvitefunction = true
        invokedRejectInviteCount += 1
        invokedRejectInviteParameters = (userId, invite)
        if let error = rejectInviteUserIdInviteThrowableError3 {
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
    public var sendNewShareInvitesUserIdShareIdNewShareInvitesThrowableError7: Error?
    public var closureSendNewShareInvites: () -> () = {}
    public var invokedSendNewShareInvitesfunction = false
    public var invokedSendNewShareInvitesCount = 0
    public var invokedSendNewShareInvitesParameters: (userId: String, shareId: String, newShareInvites: [ShareNewUserInvite])?
    public var invokedSendNewShareInvitesParametersList = [(userId: String, shareId: String, newShareInvites: [ShareNewUserInvite])]()

    public func sendNewShareInvites(userId: String, shareId: String, newShareInvites: [ShareNewUserInvite]) async throws {
        invokedSendNewShareInvitesfunction = true
        invokedSendNewShareInvitesCount += 1
        invokedSendNewShareInvitesParameters = (userId, shareId, newShareInvites)
        if let error = sendNewShareInvitesUserIdShareIdNewShareInvitesThrowableError7 {
            throw error
        }
        closureSendNewShareInvites()
    }
    // MARK: - ⚡️ ShareInviteRepositoryProtocol
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
