// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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

@testable import Client
import Core
import Entities
import Foundation
import ProtonCoreLogin

public final class ShareInviteRepositoryProtocolMock: @unchecked Sendable, ShareInviteRepositoryProtocol {

    public init() {}

    // MARK: - getAllPendingInvites
    public var getAllPendingInvitesShareIdThrowableError: Error?
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
        if let error = getAllPendingInvitesShareIdThrowableError {
            throw error
        }
        closureGetAllPendingInvites()
        return stubbedGetAllPendingInvitesResult
    }
    // MARK: - sendInvite
    public var sendInviteShareIdInviteeDataTargetTypeShareRoleThrowableError: Error?
    public var closureSendInvite: () -> () = {}
    public var invokedSendInvitefunction = false
    public var invokedSendInviteCount = 0
    public var invokedSendInviteParameters: (shareId: String, inviteeData: InviteeData, targetType: TargetType, shareRole: ShareRole)?
    public var invokedSendInviteParametersList = [(shareId: String, inviteeData: InviteeData, targetType: TargetType, shareRole: ShareRole)]()
    public var stubbedSendInviteResult: Bool!

    public func sendInvite(shareId: String, inviteeData: InviteeData, targetType: TargetType, shareRole: ShareRole) async throws -> Bool {
        invokedSendInvitefunction = true
        invokedSendInviteCount += 1
        invokedSendInviteParameters = (shareId, inviteeData, targetType, shareRole)
        invokedSendInviteParametersList.append((shareId, inviteeData, targetType, shareRole))
        if let error = sendInviteShareIdInviteeDataTargetTypeShareRoleThrowableError {
            throw error
        }
        closureSendInvite()
        return stubbedSendInviteResult
    }
    // MARK: - promoteNewUserInvite
    public var promoteNewUserInviteShareIdInviteIdKeysThrowableError: Error?
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
        if let error = promoteNewUserInviteShareIdInviteIdKeysThrowableError {
            throw error
        }
        closurePromoteNewUserInvite()
        return stubbedPromoteNewUserInviteResult
    }
    // MARK: - sendInviteReminder
    public var sendInviteReminderShareIdInviteIdThrowableError: Error?
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
        if let error = sendInviteReminderShareIdInviteIdThrowableError {
            throw error
        }
        closureSendInviteReminder()
        return stubbedSendInviteReminderResult
    }
    // MARK: - deleteInvite
    public var deleteInviteShareIdInviteIdThrowableError: Error?
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
        if let error = deleteInviteShareIdInviteIdThrowableError {
            throw error
        }
        closureDeleteInvite()
        return stubbedDeleteInviteResult
    }
    // MARK: - deleteNewUserInvite
    public var deleteNewUserInviteShareIdInviteIdThrowableError: Error?
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
        if let error = deleteNewUserInviteShareIdInviteIdThrowableError {
            throw error
        }
        closureDeleteNewUserInvite()
        return stubbedDeleteNewUserInviteResult
    }
}
