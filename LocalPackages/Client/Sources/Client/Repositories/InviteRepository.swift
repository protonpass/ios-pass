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

// sourcery: AutoMockable
public protocol InviteRepositoryProtocol: Sendable {
    var currentPendingInvites: CurrentValueSubject<[InviteType], Never> { get }

    func loadLocalInvites(userId: String) async throws
    func acceptInvite(_ invite: InviteType, and keys: [ItemKey]) async throws -> Share?

    @discardableResult
    func rejectInvite(_ invite: InviteType) async throws -> Bool
    func refreshInvites(userId: String) async throws
    func removeCachedInvite(containing inviteToken: String) async

    // MARK: - Invite Creation
}

// sourcery: AutoMockable
public protocol ShareInviteRepositoryProtocol: Sendable {
    func getAllPendingInvites(shareId: String) async throws -> ShareInvites

    func sendInvites(shareId: String,
                     itemId: String?,
                     inviteesData: [InviteeData],
                     targetType: TargetType) async throws -> Bool

    func promoteNewUserInvite(shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool

    @discardableResult
    func sendInviteReminder(shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteInvite(shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteNewUserInvite(shareId: String, inviteId: String) async throws -> Bool

    func getInviteRecommendations(shareId: String,
                                  query: InviteRecommendationsQuery) async throws -> InviteRecommendations

    func checkAddresses(shareId: String, emails: [String]) async throws -> [String]
}

public typealias FullInviteRepositoryProtocol = InviteRepositoryProtocol & ShareInviteRepositoryProtocol

public actor InviteRepository: FullInviteRepositoryProtocol {
    private let remoteDatasource: any RemoteInviteDatasourceProtocol
    private let localDatasource: any LocalInviteDatasourceProtocol
    private let logger: Logger
    private let userManager: any UserManagerProtocol

    public nonisolated let currentPendingInvites: CurrentValueSubject<[InviteType], Never> = .init([])

    public init(remoteDatasource: any RemoteInviteDatasourceProtocol,
                localDatasource: any LocalInviteDatasourceProtocol,
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
        async let getUserInvites = try localDatasource.getUserInvites(userId: userId)
        async let getGroupInvites = try localDatasource.getGroupInvites(userId: userId)

        let (groupInvites, userInvites) = try await (getGroupInvites, getUserInvites)
        mergeInvites(groupInvites: groupInvites, userInvites: userInvites)
    }

    func acceptInvite(_ invite: InviteType, and keys: [ItemKey]) async throws -> Share? {
        let userId = try await userManager.getActiveUserId()
        let inviteToken = invite.inviteToken
        logger.trace("Accepting invite \(inviteToken)")
        let request = AcceptInviteRequest(keys: keys)

        do {
            switch invite {
            case .user:
                let share = try await remoteDatasource.acceptInvite(userId: userId,
                                                                    inviteToken: inviteToken,
                                                                    request: request)
                logger.trace("Accepted the invite with token \(inviteToken)")
                return share
            case .group:
                _ = try await remoteDatasource.acceptGroupInvite(userId: userId,
                                                                 inviteToken: inviteToken,
                                                                 request: request)
                logger.trace("Accepted the invite with token \(inviteToken)")
                return nil
            }
        } catch {
            logger.warning("Failed to accept non-existing invite \(inviteToken)")
            try await removeLocalOutdateInvite(userId: userId, error: error, invite: invite)
            throw error
        }
    }

    func rejectInvite(_ invite: InviteType) async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        let inviteToken = invite.inviteToken
        logger.trace("Reject invite \(inviteToken)")

        do {
            let rejectedStatus: Bool
            switch invite {
            case .user:
                rejectedStatus = try await remoteDatasource.rejectInvite(userId: userId,
                                                                         inviteToken: inviteToken)
                logger.trace("Invite rejection status \(rejectedStatus)")
            case .group:
                rejectedStatus = try await remoteDatasource.rejectGroupInvite(userId: userId,
                                                                              inviteToken: inviteToken)
                logger.trace("Group Invite rejection status \(rejectedStatus)")
            }
            return rejectedStatus
        } catch {
            logger.warning("Failed to reject non-existing invite \(inviteToken)")
            try await removeLocalOutdateInvite(userId: userId, error: error, invite: invite)
            throw error
        }
    }

    func refreshInvites(userId: String) async throws {
        let userInvites = try await updateUserInvite(userId)
        ///  The following should fail silently as only org admins have the right to fetch group invites
        let groupInvites = try? await updateGroupInvite(userId)

        mergeInvites(groupInvites: groupInvites ?? [], userInvites: userInvites)
    }

    func removeCachedInvite(containing inviteToken: String) async {
        logger.trace("Removing current cached invite containing inviteToken \(inviteToken)")
        let newInvites = currentPendingInvites.value.filter { $0.inviteToken != inviteToken }
        currentPendingInvites.send(newInvites)
    }
}

// MARK: - Shares

public extension InviteRepository {
    func getAllPendingInvites(shareId: String) async throws -> ShareInvites {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
            let userId = try await userManager.getActiveUserId()
            let invites = try await remoteDatasource.getPendingInvites(userId: userId, sharedId: shareId)
            let existingCount = "\(invites.existingUserInvites.count) exising user invites"
            let newCount = "\(invites.newUserInvites.count) new user invites"
            logger.trace("Got \(existingCount), \(newCount) for \(shareId)")
            return invites
        } catch {
            logger.error(message: "Failed to get pending invites for share \(shareId)", error: error)
            throw error
        }
    }

    func sendInvites(shareId: String,
                     itemId: String?,
                     inviteesData: [InviteeData],
                     targetType: TargetType) async throws -> Bool {
        let userInvites = inviteesData.existingUserInvitesRequests(targetType: targetType, itemId: itemId)
        var newUserInvites = [InviteNewUserToShareRequest]()
        if targetType != .item {
            newUserInvites = inviteesData.newUserInvitesRequests(targetType: targetType, itemId: itemId)
        }

        if userInvites.isEmpty, newUserInvites.isEmpty {
            return false
        }

        if !userInvites.isEmpty, newUserInvites.isEmpty {
            return try await sendProtonInvites(shareId: shareId, requests: userInvites)
        } else if userInvites.isEmpty, !newUserInvites.isEmpty {
            return try await sendExternalInvites(shareId: shareId, requests: newUserInvites)
        } else {
            async let invites = sendProtonInvites(shareId: shareId, requests: userInvites)
            async let newInvites = sendExternalInvites(shareId: shareId, requests: newUserInvites)

            let (invitesSuccess, newInvitesSuccess) = try await (invites, newInvites)
            return invitesSuccess && newInvitesSuccess
        }
    }

    func promoteNewUserInvite(shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool {
        logger.trace("Promoting new user invite \(inviteId) for share \(shareId)")
        do {
            let userId = try await userManager.getActiveUserId()
            let promoted = try await remoteDatasource.promoteNewUserInvite(userId: userId,
                                                                           shareId: shareId,
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
            let userId = try await userManager.getActiveUserId()
            let sent = try await remoteDatasource.sendInviteReminder(userId: userId,
                                                                     shareId: shareId,
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
            let userId = try await userManager.getActiveUserId()
            let deleted = try await remoteDatasource.deleteShareInvite(userId: userId,
                                                                       shareId: shareId,
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
            let userId = try await userManager.getActiveUserId()
            let deleted = try await remoteDatasource.deleteShareNewUserInvite(userId: userId,
                                                                              shareId: shareId,
                                                                              inviteId: inviteId)
            logger.info("Deleted new user \(deleted) for share \(shareId) invite \(inviteId)")
            return deleted
        } catch {
            logger.error(message: "Failed to delete new user invite \(inviteId) for share \(shareId)",
                         error: error)
            throw error
        }
    }

    func getInviteRecommendations(shareId: String,
                                  query: InviteRecommendationsQuery) async throws -> InviteRecommendations {
        logger.trace("Getting invite recommendations for share \(shareId)")
        let userId = try await userManager.getActiveUserId()
        return try await remoteDatasource.getInviteRecommendations(userId: userId, shareId: shareId, query: query)
    }

    func checkAddresses(shareId: String, emails: [String]) async throws -> [String] {
        let userId = try await userManager.getActiveUserId()
        // The endpoint accepts 10 addresses at max so we check in batch
        return try await withThrowingTaskGroup(of: [String].self, returning: [String].self) { [weak self] group in
            guard let self else { return [] }
            for batch in emails.chunked(into: 10) {
                group.addTask {
                    try await self.remoteDatasource.checkAddresses(userId: userId, shareId: shareId, emails: batch)
                }
            }

            var acceptedAddresses = [String]()
            for try await batch in group {
                acceptedAddresses.append(contentsOf: batch)
            }
            return acceptedAddresses
        }
    }
}

private extension InviteRepository {
    func sendProtonInvites(shareId: String,
                           requests: [InviteUserToShareRequest]) async throws -> Bool {
        logger.trace("Inviting batch Proton users to share \(shareId)")
        do {
            let request = InviteMultipleUsersToShareRequest(invites: requests)
            let userId = try await userManager.getActiveUserId()
            let inviteStatus = try await remoteDatasource.inviteMultipleProtonUsers(userId: userId,
                                                                                    shareId: shareId,
                                                                                    request: request)
            logger.info("Invited batch Proton users to \(shareId)")
            return inviteStatus
        } catch {
            logger.error(message: "Failed to invite batch Proton users to share \(shareId)",
                         error: error)
            throw error
        }
    }

    func sendExternalInvites(shareId: String,
                             requests: [InviteNewUserToShareRequest]) async throws -> Bool {
        logger.trace("Inviting multiple external users to share \(shareId)")
        do {
            let request = InviteMultipleNewUsersToShareRequest(newUserInvites: requests)
            let userId = try await userManager.getActiveUserId()
            let inviteStatus = try await remoteDatasource.inviteMultipleExternalUsers(userId: userId,
                                                                                      shareId: shareId,
                                                                                      request: request)
            logger.info("Invited multiple external users to \(shareId)")
            return inviteStatus
        } catch {
            logger.error(message: "Failed to invite multiple external users to share \(shareId)",
                         error: error)
            throw error
        }
    }

    func updateUserInvite(_ userId: String) async throws -> [UserInvite] {
        logger.trace("Refreshing user invites for user \(userId)")
        let invites = try await remoteDatasource.getPendingInvitesForUser(userId: userId)
        logger.trace("Fetched \(invites.count) user invites for user \(userId)")
        try await localDatasource.removeAllUserInvites(userId: userId)
        logger.trace("Removed old local user invites for user \(userId)")
        try await localDatasource.upsertUserInvites(userId: userId, invites: invites)
        logger.trace("Upserted \(invites.count) user invites for user \(userId)")
        return invites
    }

    func updateGroupInvite(_ userId: String) async throws -> [GroupInvite] {
        logger.trace("Refreshing group invites for user \(userId)")
        var invites = [GroupInvite]()
        var lastToken: String?
        while true {
            let results = try await remoteDatasource.getPendingGroupInvitesForUser(lastToken: lastToken,
                                                                                   userId: userId)
            invites.append(contentsOf: results.invites)
            if results.invites.isEmpty || results.lastID == nil {
                break
            }
            lastToken = results.lastID
        }

        logger.trace("Fetched \(invites.count) group invites for user \(userId)")
        try await localDatasource.removeAllGroupInvites(userId: userId)
        logger.trace("Removed old local group invites for user \(userId)")
        try await localDatasource.upsertGroupInvites(userId: userId, invites: invites)
        logger.trace("Upserted \(invites.count) group invites for user \(userId)")
        return invites
    }

    func mergeInvites(groupInvites: [GroupInvite], userInvites: [UserInvite]) {
        let invites: [InviteType] = groupInvites.map { .group($0) } + userInvites.map { .user($0) }

        currentPendingInvites.send(invites)
    }

    func removeLocalOutdateInvite(userId: String, error: Error, invite: InviteType) async throws {
        // Invite doesn't exist anymore (stale cache or race condition)

        guard error.asPassApiError == .invalidValidation else {
            return
        }
        switch invite {
        case let .user(invite):
            try await localDatasource.removeUserInvite(userId: userId, invite: invite)
        case let .group(invite):
            try await localDatasource.removeGroupInvite(userId: userId, invite: invite)
        }
        try await loadLocalInvites(userId: userId)
    }
}
