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
import Core
import Entities
import Foundation
import ProtonCoreLogin

public final class ShareInviteRepositoryProtocolMock: @unchecked Sendable, ShareInviteRepositoryProtocol {

    public init() {}

    // MARK: - getAllPendingInvites
    public var getAllPendingInvitesShareIdThrowableError1: Error?
    public var closureGetAllPendingInvites: () -> () = {}
    public var invokedGetAllPendingInvitesfunction = false
    public var invokedGetAllPendingInvitesCount = 0
    public var invokedGetAllPendingInvitesParameters: (shareId: String, Void)?
    public var invokedGetAllPendingInvitesParametersList = [(shareId: String, Void)]()
    public var stubbedGetAllPendingInvitesResult: ShareInvites!

    public func getAllPendingInvites(shareId: String) async throws -> ShareInvites {
        invokedGetAllPendingInvitesfunction = true
        invokedGetAllPendingInvitesCount += 1
        invokedGetAllPendingInvitesParameters = (shareId, ())
        invokedGetAllPendingInvitesParametersList.append((shareId, ()))
        if let error = getAllPendingInvitesShareIdThrowableError1 {
            throw error
        }
        closureGetAllPendingInvites()
        return stubbedGetAllPendingInvitesResult
    }
    // MARK: - sendInvites
    public var sendInvitesShareIdItemIdInviteesDataTargetTypeThrowableError2: Error?
    public var closureSendInvites: () -> () = {}
    public var invokedSendInvitesfunction = false
    public var invokedSendInvitesCount = 0
    public var invokedSendInvitesParameters: (shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType)?
    public var invokedSendInvitesParametersList = [(shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType)]()
    public var stubbedSendInvitesResult: Bool!

    public func sendInvites(shareId: String, itemId: String?, inviteesData: [InviteeData], targetType: TargetType) async throws -> Bool {
        invokedSendInvitesfunction = true
        invokedSendInvitesCount += 1
        invokedSendInvitesParameters = (shareId, itemId, inviteesData, targetType)
        invokedSendInvitesParametersList.append((shareId, itemId, inviteesData, targetType))
        if let error = sendInvitesShareIdItemIdInviteesDataTargetTypeThrowableError2 {
            throw error
        }
        closureSendInvites()
        return stubbedSendInvitesResult
    }
    // MARK: - promoteNewUserInvite
    public var promoteNewUserInviteShareIdInviteIdKeysThrowableError3: Error?
    public var closurePromoteNewUserInvite: () -> () = {}
    public var invokedPromoteNewUserInvitefunction = false
    public var invokedPromoteNewUserInviteCount = 0
    public var invokedPromoteNewUserInviteParameters: (shareId: String, inviteId: String, keys: [ItemKey])?
    public var invokedPromoteNewUserInviteParametersList = [(shareId: String, inviteId: String, keys: [ItemKey])]()
    public var stubbedPromoteNewUserInviteResult: Bool!

    public func promoteNewUserInvite(shareId: String, inviteId: String, keys: [ItemKey]) async throws -> Bool {
        invokedPromoteNewUserInvitefunction = true
        invokedPromoteNewUserInviteCount += 1
        invokedPromoteNewUserInviteParameters = (shareId, inviteId, keys)
        invokedPromoteNewUserInviteParametersList.append((shareId, inviteId, keys))
        if let error = promoteNewUserInviteShareIdInviteIdKeysThrowableError3 {
            throw error
        }
        closurePromoteNewUserInvite()
        return stubbedPromoteNewUserInviteResult
    }
    // MARK: - sendInviteReminder
    public var sendInviteReminderShareIdInviteIdThrowableError4: Error?
    public var closureSendInviteReminder: () -> () = {}
    public var invokedSendInviteReminderfunction = false
    public var invokedSendInviteReminderCount = 0
    public var invokedSendInviteReminderParameters: (shareId: String, inviteId: String)?
    public var invokedSendInviteReminderParametersList = [(shareId: String, inviteId: String)]()
    public var stubbedSendInviteReminderResult: Bool!

    public func sendInviteReminder(shareId: String, inviteId: String) async throws -> Bool {
        invokedSendInviteReminderfunction = true
        invokedSendInviteReminderCount += 1
        invokedSendInviteReminderParameters = (shareId, inviteId)
        invokedSendInviteReminderParametersList.append((shareId, inviteId))
        if let error = sendInviteReminderShareIdInviteIdThrowableError4 {
            throw error
        }
        closureSendInviteReminder()
        return stubbedSendInviteReminderResult
    }
    // MARK: - deleteInvite
    public var deleteInviteShareIdInviteIdThrowableError5: Error?
    public var closureDeleteInvite: () -> () = {}
    public var invokedDeleteInvitefunction = false
    public var invokedDeleteInviteCount = 0
    public var invokedDeleteInviteParameters: (shareId: String, inviteId: String)?
    public var invokedDeleteInviteParametersList = [(shareId: String, inviteId: String)]()
    public var stubbedDeleteInviteResult: Bool!

    public func deleteInvite(shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteInvitefunction = true
        invokedDeleteInviteCount += 1
        invokedDeleteInviteParameters = (shareId, inviteId)
        invokedDeleteInviteParametersList.append((shareId, inviteId))
        if let error = deleteInviteShareIdInviteIdThrowableError5 {
            throw error
        }
        closureDeleteInvite()
        return stubbedDeleteInviteResult
    }
    // MARK: - deleteNewUserInvite
    public var deleteNewUserInviteShareIdInviteIdThrowableError6: Error?
    public var closureDeleteNewUserInvite: () -> () = {}
    public var invokedDeleteNewUserInvitefunction = false
    public var invokedDeleteNewUserInviteCount = 0
    public var invokedDeleteNewUserInviteParameters: (shareId: String, inviteId: String)?
    public var invokedDeleteNewUserInviteParametersList = [(shareId: String, inviteId: String)]()
    public var stubbedDeleteNewUserInviteResult: Bool!

    public func deleteNewUserInvite(shareId: String, inviteId: String) async throws -> Bool {
        invokedDeleteNewUserInvitefunction = true
        invokedDeleteNewUserInviteCount += 1
        invokedDeleteNewUserInviteParameters = (shareId, inviteId)
        invokedDeleteNewUserInviteParametersList.append((shareId, inviteId))
        if let error = deleteNewUserInviteShareIdInviteIdThrowableError6 {
            throw error
        }
        closureDeleteNewUserInvite()
        return stubbedDeleteNewUserInviteResult
    }
    // MARK: - getInviteRecommendations
    public var getInviteRecommendationsShareIdQueryThrowableError7: Error?
    public var closureGetInviteRecommendations: () -> () = {}
    public var invokedGetInviteRecommendationsfunction = false
    public var invokedGetInviteRecommendationsCount = 0
    public var invokedGetInviteRecommendationsParameters: (shareId: String, query: InviteRecommendationsQuery)?
    public var invokedGetInviteRecommendationsParametersList = [(shareId: String, query: InviteRecommendationsQuery)]()
    public var stubbedGetInviteRecommendationsResult: InviteRecommendations!

    public func getInviteRecommendations(shareId: String, query: InviteRecommendationsQuery) async throws -> InviteRecommendations {
        invokedGetInviteRecommendationsfunction = true
        invokedGetInviteRecommendationsCount += 1
        invokedGetInviteRecommendationsParameters = (shareId, query)
        invokedGetInviteRecommendationsParametersList.append((shareId, query))
        if let error = getInviteRecommendationsShareIdQueryThrowableError7 {
            throw error
        }
        closureGetInviteRecommendations()
        return stubbedGetInviteRecommendationsResult
    }
    // MARK: - checkAddresses
    public var checkAddressesShareIdEmailsThrowableError8: Error?
    public var closureCheckAddresses: () -> () = {}
    public var invokedCheckAddressesfunction = false
    public var invokedCheckAddressesCount = 0
    public var invokedCheckAddressesParameters: (shareId: String, emails: [String])?
    public var invokedCheckAddressesParametersList = [(shareId: String, emails: [String])]()
    public var stubbedCheckAddressesResult: [String]!

    public func checkAddresses(shareId: String, emails: [String]) async throws -> [String] {
        invokedCheckAddressesfunction = true
        invokedCheckAddressesCount += 1
        invokedCheckAddressesParameters = (shareId, emails)
        invokedCheckAddressesParametersList.append((shareId, emails))
        if let error = checkAddressesShareIdEmailsThrowableError8 {
            throw error
        }
        closureCheckAddresses()
        return stubbedCheckAddressesResult
    }
}
