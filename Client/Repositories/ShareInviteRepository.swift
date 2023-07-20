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
import ProtonCore_Login

public protocol ShareInviteRepositoryProtocol {
    // MARK: - Share Invites

    func getAllPendingInvites(for shareId: String) async throws -> [ShareInvite]

    func sendInvite(shareId: String,
                    keys: [ItemKey],
                    email: String,
                    targetType: String) async throws -> Bool

    func sendInviteReminder(shareId: String, userId: String) async throws -> Bool

    func deleteInvite(shareId: String, userId: String) async throws -> Bool
}

public final class ShareInviteRepository: ShareInviteRepositoryProtocol {
    public let remoteShareInviteDataSource: RemoteShareInviteDatasourceProtocol
    public let logger: Logger

    public init(remoteShareInviteDataSource: RemoteShareInviteDatasourceProtocol,
                logManager: LogManager) {
        self.remoteShareInviteDataSource = remoteShareInviteDataSource
        logger = .init(manager: logManager)
    }
}

// MARK: - Share Invites

public extension ShareInviteRepository {
    func getAllPendingInvites(for shareId: String) async throws -> [ShareInvite] {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
            let invites = try await remoteShareInviteDataSource.getPendingInvitesForShare(sharedId: shareId)
            logger.trace("Got \(invites.count) pending invites for \(shareId)")
            return invites
        } catch {
            logger.debug("Failed to get pending invites for share \(shareId). \(String(describing: error))")
            throw error
        }
    }

    func sendInvite(shareId: String,
                    keys: [ItemKey],
                    email: String,
                    targetType: String) async throws -> Bool {
        logger.trace("Inviting user to share \(shareId)")
        do {
            let request = InviteUserToShareRequest(keys: keys, email: email, targetType: targetType)
            let inviteStatus = try await remoteShareInviteDataSource.inviteUser(shareId: shareId, request: request)
            logger.trace("Invited \(email) for \(shareId)")
            return inviteStatus
        } catch {
            logger.debug("Failed to invite user \(email) for share \(shareId). \(String(describing: error))")
            throw error
        }
    }

    func sendInviteReminder(shareId: String, userId: String) async throws -> Bool {
        logger.trace("Send reminder to user \(userId) for share \(shareId)")
        do {
            let reminderStatus = try await remoteShareInviteDataSource.sendInviteReminderToUser(shareId: shareId,
                                                                                                userId: userId)
            logger.trace("Reminder status \(reminderStatus) for \(shareId)")
            return reminderStatus
        } catch {
            logger
                .debug("Failed to send reminder to user \(userId) for share \(shareId). \(String(describing: error))")
            throw error
        }
    }

    func deleteInvite(shareId: String, userId: String) async throws -> Bool {
        logger.trace("Delete invite to user \(userId) for share \(shareId)")
        do {
            let deleteStatus = try await remoteShareInviteDataSource.deleteShareUserInvite(shareId: shareId,
                                                                                           userId: userId)
            logger.trace("Deletion status \(deleteStatus) for \(shareId)")
            return deleteStatus
        } catch {
            logger
                .debug("Failed to delete invite to user \(userId) for share \(shareId). \(String(describing: error))")
            throw error
        }
    }
}
