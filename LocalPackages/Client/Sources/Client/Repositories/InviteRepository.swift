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

@preconcurrency import Combine
import Core
import Entities
import Foundation
import ProtonCoreLogin

public protocol InviteRepositoryProtocol: Sendable {
    var currentPendingInvites: CurrentValueSubject<[UserInvite], Never> { get }

    func getPendingInvitesForUser() async throws -> [UserInvite]
    func acceptInvite(with inviteToken: String, and keys: [ItemKey]) async throws -> Bool

    @discardableResult
    func rejectInvite(with inviteToken: String) async throws -> Bool
    func refreshInvites() async
    func removeCachedInvite(containing inviteToken: String) async
}

public actor InviteRepository: InviteRepositoryProtocol {
    public let remoteInviteDatasource: RemoteInviteDatasourceProtocol
    public let logger: Logger
    public nonisolated let currentPendingInvites: CurrentValueSubject<[UserInvite], Never> = .init([])
    private var refreshInviteTask: Task<Void, Never>?

    public init(remoteInviteDatasource: RemoteInviteDatasourceProtocol,
                logManager: LogManagerProtocol) {
        self.remoteInviteDatasource = remoteInviteDatasource
        logger = .init(manager: logManager)
    }
}

public extension InviteRepository {
    func getPendingInvitesForUser() async throws -> [UserInvite] {
        logger.trace("Getting all pending invites for user")
        do {
            let invites = try await remoteInviteDatasource.getPendingInvitesForUser()
            logger.trace("Got \(invites.count) pending invites")
            return invites
        } catch {
            logger.error(message: "Failed to get pending invites for user.", error: error)
            throw error
        }
    }

    func acceptInvite(with inviteToken: String, and keys: [ItemKey]) async throws -> Bool {
        logger.trace("Accepting invite \(inviteToken)")
        let request = AcceptInviteRequest(keys: keys)
        let acceptStatus = try await remoteInviteDatasource.acceptInvite(inviteToken: inviteToken,
                                                                         request: request)
        logger.trace("Invite acceptance status \(acceptStatus)")
        return acceptStatus
    }

    func rejectInvite(with inviteToken: String) async throws -> Bool {
        logger.trace("Reject invite \(inviteToken)")
        let rejectedStatus = try await remoteInviteDatasource.rejectInvite(inviteToken: inviteToken)
        logger.trace("Invite rejection status \(rejectedStatus)")
        return rejectedStatus
    }

    func refreshInvites() async {
        refreshInviteTask?.cancel()
        refreshInviteTask = Task { [weak self] in
            guard let self else {
                return
            }
            logger.trace("Refreshing all user invitations")
            do {
                if Task.isCancelled {
                    return
                }
                let invites = try await getPendingInvitesForUser()
                if Task.isCancelled {
                    return
                }
                if invites != currentPendingInvites.value {
                    currentPendingInvites.send(invites)
                }
                logger.trace("Invites refreshed with \(invites)")
            } catch {
                logger.error(message: "Could not refresh all the user's invitations", error: error)
            }
        }
    }

    func removeCachedInvite(containing inviteToken: String) async {
        logger.trace("Removing current cached invite containing inviteToken \(inviteToken)")
        let newInvites = currentPendingInvites.value.filter { $0.inviteToken != inviteToken }
        currentPendingInvites.send(newInvites)
    }
}
