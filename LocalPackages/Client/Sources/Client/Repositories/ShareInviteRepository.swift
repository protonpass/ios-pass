//
// ShareInviteRepository.swift
// Proton Pass - Created on 17/07/2023.
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

import Core
import Entities
import Foundation
import ProtonCoreLogin

public enum InviteeData {
    case existing(email: String, keys: [ItemKey])
    case new(email: String, signature: String)
}

// sourcery: AutoMockable
public protocol ShareInviteRepositoryProtocol {
    func getAllPendingInvites(shareId: String) async throws -> ShareInvites

    func sendInvite(shareId: String,
                    inviteeData: InviteeData,
                    targetType: TargetType,
                    shareRole: ShareRole) async throws -> Bool

    func promoteNewUserInvite(shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool

    @discardableResult
    func sendInviteReminder(shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteInvite(shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteNewUserInvite(shareId: String, inviteId: String) async throws -> Bool
}

public actor ShareInviteRepository: ShareInviteRepositoryProtocol {
    private let remoteDataSource: RemoteShareInviteDatasourceProtocol
    private let logger: Logger

    public init(remoteDataSource: RemoteShareInviteDatasourceProtocol,
                logManager: LogManagerProtocol) {
        self.remoteDataSource = remoteDataSource
        logger = .init(manager: logManager)
    }
}

// MARK: - Share Invites

public extension ShareInviteRepository {
    func getAllPendingInvites(shareId: String) async throws -> ShareInvites {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
            let invites = try await remoteDataSource.getPendingInvites(sharedId: shareId)
            let existingCount = "\(invites.existingUserInvites.count) exising user invites"
            let newCount = "\(invites.newUserInvites.count) new user invites"
            logger.trace("Got \(existingCount), \(newCount) for \(shareId)")
            return invites
        } catch {
            logger.error(message: "Failed to get pending invites for share \(shareId)", error: error)
            throw error
        }
    }

    func sendInvite(shareId: String,
                    inviteeData: InviteeData,
                    targetType: TargetType,
                    shareRole: ShareRole) async throws -> Bool {
        switch inviteeData {
        case let .existing(email, keys):
            try await sendProtonInvite(shareId: shareId,
                                       email: email,
                                       keys: keys,
                                       targetType: targetType,
                                       shareRole: shareRole)
        case let .new(email, signature):
            try await sendExternalInvite(shareId: shareId,
                                         email: email,
                                         signature: signature,
                                         targetType: targetType,
                                         shareRole: shareRole)
        }
    }

    func promoteNewUserInvite(shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool {
        logger.trace("Promoting new user invite \(inviteId) for share \(shareId)")
        do {
            let promoted = try await remoteDataSource.promoteNewUserInvite(shareId: shareId,
                                                                           inviteId: inviteId,
                                                                           keys: keys)
            logger.info("Promoted \(promoted) new user invite \(inviteId) for share \(shareId)")
            return promoted
        } catch {
            logger.error(message: "Failed to promote new user invite \(inviteId) for share \(shareId)",
                         error: error)
            throw error
        }
    }

    func sendInviteReminder(shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Sending reminder for share \(shareId) invite \(inviteId)")
        do {
            let sent = try await remoteDataSource.sendInviteReminder(shareId: shareId,
                                                                     inviteId: inviteId)
            logger.info("Reminded \(sent) for \(shareId) invite \(inviteId)")
            return sent
        } catch {
            logger.error(message: "Failed to send reminder for share \(shareId) invite \(inviteId)",
                         error: error)
            throw error
        }
    }

    func deleteInvite(shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Deleting invite \(inviteId) for share \(shareId)")
        do {
            let deleted = try await remoteDataSource.deleteShareInvite(shareId: shareId,
                                                                       inviteId: inviteId)
            logger.info("Deleted \(deleted) for share \(shareId) invite \(inviteId)")
            return deleted
        } catch {
            logger.error(message: "Failed to delete invite \(inviteId) for share \(shareId)",
                         error: error)
            throw error
        }
    }

    func deleteNewUserInvite(shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Deleting new user invite \(inviteId) for share \(shareId)")
        do {
            let deleted = try await remoteDataSource.deleteShareNewUserInvite(shareId: shareId,
                                                                              inviteId: inviteId)
            logger.info("Deleted new user \(deleted) for share \(shareId) invite \(inviteId)")
            return deleted
        } catch {
            logger.error(message: "Failed to delete new user invite \(inviteId) for share \(shareId)",
                         error: error)
            throw error
        }
    }
}

private extension ShareInviteRepository {
    func sendProtonInvite(shareId: String,
                          email: String,
                          keys: [ItemKey],
                          targetType: TargetType,
                          shareRole: ShareRole) async throws -> Bool {
        logger.trace("Inviting Proton user \(email) to share \(shareId)")
        do {
            let request = InviteUserToShareRequest(keys: keys,
                                                   email: email,
                                                   targetType: targetType,
                                                   shareRole: shareRole)
            let inviteStatus = try await remoteDataSource.inviteProtonUser(shareId: shareId,
                                                                           request: request)
            logger.info("Invited Proton user \(email) to \(shareId)")
            return inviteStatus
        } catch {
            logger.error(message: "Failed to invite Proton user \(email) to share \(shareId)",
                         error: error)
            throw error
        }
    }

    func sendExternalInvite(shareId: String,
                            email: String,
                            signature: String,
                            targetType: TargetType,
                            shareRole: ShareRole) async throws -> Bool {
        logger.trace("Inviting external user \(email) to share \(shareId)")
        do {
            let request = InviteNewUserToShareRequest(email: email,
                                                      targetType: targetType,
                                                      signature: signature,
                                                      shareRole: shareRole)
            let inviteStatus = try await remoteDataSource.inviteExternalUser(shareId: shareId,
                                                                             request: request)
            logger.info("Invited external user \(email) to \(shareId)")
            return inviteStatus
        } catch {
            logger.error(message: "Failed to invite external user \(email) to share \(shareId)",
                         error: error)
            throw error
        }
    }
}
