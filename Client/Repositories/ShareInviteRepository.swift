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

// sourcery: AutoMockable
public protocol ShareInviteRepositoryProtocol {
    func getAllPendingInvites(shareId: String) async throws -> [ShareInvite]

    func sendInvite(shareId: String,
                    keys: [ItemKey],
                    email: String,
                    targetType: TargetType,
                    shareRole: ShareRole) async throws -> Bool

    func sendInviteReminder(shareId: String, inviteId: String) async throws -> Bool

    func deleteInvite(shareId: String, inviteId: String) async throws -> Bool
}

public final class ShareInviteRepository: ShareInviteRepositoryProtocol {
    public let remoteDataSource: RemoteShareInviteDatasourceProtocol
    public let logger: Logger

    public init(remoteDataSource: RemoteShareInviteDatasourceProtocol,
                logManager: LogManagerProtocol) {
        self.remoteDataSource = remoteDataSource
        logger = .init(manager: logManager)
    }
}

// MARK: - Share Invites

public extension ShareInviteRepository {
    func getAllPendingInvites(shareId: String) async throws -> [ShareInvite] {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
            let invites = try await remoteDataSource.getPendingInvites(sharedId: shareId)
            logger.trace("Got \(invites.count) pending invites for \(shareId)")
            return invites
        } catch {
            logger.error(message: "Failed to get pending invites for share \(shareId)", error: error)
            throw error
        }
    }

    func sendInvite(shareId: String,
                    keys: [ItemKey],
                    email: String,
                    targetType: TargetType,
                    shareRole: ShareRole) async throws -> Bool {
        logger.trace("Inviting \(email) to share \(shareId)")
        do {
            let request = InviteUserToShareRequest(keys: keys,
                                                   email: email,
                                                   targetType: targetType,
                                                   shareRole: shareRole)
            let inviteStatus = try await remoteDataSource.inviteUser(shareId: shareId, request: request)
            logger.info("Invited \(email) to \(shareId)")
            return inviteStatus
        } catch {
            logger.error(message: "Failed to invite \(email) to share \(shareId)", error: error)
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
}
