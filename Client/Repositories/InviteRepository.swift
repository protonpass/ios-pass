//
// InviteRepository.swift
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

public protocol InviteRepositoryProtocol {
    // MARK: - Invites

    func getPendingInvitesForUser() async throws -> [UserInvite]
    func acceptInvite(with inviteToken: String, and keys: [ItemKey]) async throws -> Bool
}

public final class InviteRepository: InviteRepositoryProtocol {
    public let remoteInviteDatasource: RemoteInviteDatasourceProtocol
    public let logger: Logger

    public init(remoteInviteDatasource: RemoteInviteDatasourceProtocol,
                logManager: LogManager) {
        self.remoteInviteDatasource = remoteInviteDatasource
        logger = .init(manager: logManager)
    }
}

// MARK: - Invites

public extension InviteRepository {
    func getPendingInvitesForUser() async throws -> [UserInvite] {
        logger.trace("Getting all pending invites for user")
        do {
            let invites = try await remoteInviteDatasource.getPendingInvitesForUser()
            logger.trace("Got \(invites.count) pending invites")
            return invites
        } catch {
            logger.debug("Failed to get pending invites for user. \(String(describing: error))")
            throw error
        }
    }

    func acceptInvite(with inviteToken: String, and keys: [ItemKey]) async throws -> Bool {
        logger.trace("Accepting invite \(inviteToken)")
        do {
            let request = AcceptInviteRequest(keys: keys)
            let acceptStatus = try await remoteInviteDatasource.acceptInvite(with: inviteToken, and: request)
            logger.trace("Invite acceptance status \(acceptStatus)")
            return acceptStatus
        } catch {
            logger.debug("Failed to accept invite \(inviteToken). \(String(describing: error))")
            throw error
        }
    }
}
