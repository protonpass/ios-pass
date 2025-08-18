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

    func loadLocalInvites(userId: String) async throws
    func acceptInvite(_ invite: UserInvite, and keys: [ItemKey]) async throws -> Share

    @discardableResult
    func rejectInvite(_ invite: UserInvite) async throws -> Bool
    // swiftlint:disable:next todo
    // TODO: Could be removed once migrated to user event
    func refreshInvites() async
    func refreshInvites(userId: String) async throws
    func removeCachedInvite(containing inviteToken: String) async
}

public actor InviteRepository: InviteRepositoryProtocol {
    private let remoteDatasource: any RemoteInviteDatasourceProtocol
    private let localDatasource: any LocalUserInviteDatasourceProtocol
    private let logger: Logger
    private var refreshInviteTask: Task<Void, Never>?
    private let userManager: any UserManagerProtocol

    public nonisolated let currentPendingInvites: CurrentValueSubject<[UserInvite], Never> = .init([])

    public init(remoteDatasource: any RemoteInviteDatasourceProtocol,
                localDatasource: any LocalUserInviteDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }
}

public extension InviteRepository {
    func loadLocalInvites(userId: String) async throws {
        let invites = try await localDatasource.getInvites(userId: userId)
        currentPendingInvites.send(invites)
    }

    // swiftlint:disable:next todo
    // TODO: Could be removed once migrated to user event
    func getPendingInvitesForUser() async throws -> [UserInvite] {
        logger.trace("Getting all pending invites for user")
        do {
            let userId = try await userManager.getActiveUserId()
            let invites = try await remoteDatasource.getPendingInvitesForUser(userId: userId)
            logger.trace("Got \(invites.count) pending invites")
            return invites
        } catch {
            logger.error(message: "Failed to get pending invites for user.", error: error)
            throw error
        }
    }

    func acceptInvite(_ invite: UserInvite, and keys: [ItemKey]) async throws -> Share {
        let inviteToken = invite.inviteToken
        logger.trace("Accepting invite \(inviteToken)")
        let request = AcceptInviteRequest(keys: keys)
        let userId = try await userManager.getActiveUserId()
        do {
            let share = try await remoteDatasource.acceptInvite(userId: userId,
                                                                inviteToken: inviteToken,
                                                                request: request)
            logger.trace("Accepted the invite with token \(inviteToken)")
            return share
        } catch {
            if error.asPassApiError == .invalidValidation {
                logger.warning("Failed to accept non-existing invite \(inviteToken)")
                // Invite doesn't exist anymore (stale cache or race condition)
                try await localDatasource.removeInvite(userId: userId, invite: invite)
                try await loadLocalInvites(userId: userId)
            }
            throw error
        }
    }

    func rejectInvite(_ invite: UserInvite) async throws -> Bool {
        let inviteToken = invite.inviteToken
        logger.trace("Reject invite \(inviteToken)")
        let userId = try await userManager.getActiveUserId()
        do {
            let rejectedStatus = try await remoteDatasource.rejectInvite(userId: userId,
                                                                         inviteToken: inviteToken)
            logger.trace("Invite rejection status \(rejectedStatus)")
            return rejectedStatus
        } catch {
            if error.asPassApiError == .invalidValidation {
                logger.warning("Failed to reject non-existing invite \(inviteToken)")
                // Invite doesn't exist anymore (stale cache or race condition)
                try await localDatasource.removeInvite(userId: userId, invite: invite)
                try await loadLocalInvites(userId: userId)
            }
            throw error
        }
    }

    func refreshInvites(userId: String) async throws {
        logger.trace("Refreshing invites for user \(userId)")
        let invites = try await remoteDatasource.getPendingInvitesForUser(userId: userId)
        logger.trace("Fetched \(invites.count) invites for user \(userId)")
        try await localDatasource.removeInvites(userId: userId)
        logger.trace("Removed old local invites for user \(userId)")
        try await localDatasource.upsertInvites(userId: userId, invites: invites)
        logger.trace("Upserted \(invites.count) updated invites for user \(userId)")
        currentPendingInvites.send(invites)
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
