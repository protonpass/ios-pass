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
    func acceptGroupInvite(with inviteToken: String, and keys: [ItemKey]) async throws

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
    private var refreshInviteTask: Task<Void, Never>?
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
//        let invites: [InviteType] = getGroupInvites.map { .group($0) } + userInvites.map { .user($0) }
//
//        currentPendingInvites.send(invites)
    }

    // swiftlint:disable:next todo
    // TODO: Could be removed once migrated to user event
    // TODO: Check if group need the same
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

    func acceptInvite(_ invite: InviteType, and keys: [ItemKey]) async throws -> Share? {
        switch invite {
        case let .user(invite):
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
                    try await localDatasource.removeUserInvites(userId: userId, invite: invite)
                    try await loadLocalInvites(userId: userId)
                }
                throw error
            }
        case let .group(invite):
            // TODO: change logic for group invite

            let inviteToken = invite.inviteToken
            logger.trace("Accepting invite \(inviteToken)")
            let request = AcceptInviteRequest(keys: keys)
            let userId = try await userManager.getActiveUserId()
            do {
                _ = try await remoteDatasource.acceptGroupInvite(userId: userId,
                                                                 inviteToken: inviteToken,
                                                                 request: request)
                logger.trace("Accepted the invite with token \(inviteToken)")
                return nil /* share */
            } catch {
                if error.asPassApiError == .invalidValidation {
                    logger.warning("Failed to accept non-existing invite \(inviteToken)")
                    // Invite doesn't exist anymore (stale cache or race condition)
                    try await localDatasource.removeGroupInvites(userId: userId, invite: invite)
                    try await loadLocalInvites(userId: userId)
                }
                throw error
            }
        }
    }

    func rejectInvite(_ invite: InviteType) async throws -> Bool {
        switch invite {
        case let .user(invite):
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
                    try await localDatasource.removeUserInvites(userId: userId, invite: invite)
                    try await loadLocalInvites(userId: userId)
                }
                throw error
            }
        // TODO: implement group reject
        case let .group(invite):
            let inviteToken = invite.inviteToken
            logger.trace("Reject invite \(inviteToken)")
            return false
        }
    }

    func refreshInvites(userId: String) async throws {
        async let updateUserInvite = try updateUserInvite(userId)
        async let updateGroupInvites = try updateGroupInvite(userId)

        let (groupInvites, userInvites) = try await (updateGroupInvites, updateUserInvite)
        mergeInvites(groupInvites: groupInvites, userInvites: userInvites)
        //        logger.trace("Refreshing invites for user \(userId)")
        //        let invites = try await remoteDatasource.getPendingInvitesForUser(userId: userId)
        //        logger.trace("Fetched \(invites.count) invites for user \(userId)")
        //        try await localDatasource.removeInvites(userId: userId)
        //        logger.trace("Removed old local invites for user \(userId)")
        //        try await localDatasource.upsertInvites(userId: userId, invites: invites)
        //        logger.trace("Upserted \(invites.count) updated invites for user \(userId)")
        //        currentPendingInvites.send(invites)
    }

    // TODO: add group invite refresh

//    func refreshFullInvites(userId: String, lastID: String?) async throws {
//        logger.trace("Refreshing invites for user \(userId)")
//        if lastID == nil {
//            async let refreshing = try refreshUserInvites(userId: userId)
//
//        async let userInvites = try remoteDatasource.getPendingInvitesForUser(userId: userId)
//
//        let userInvites = try await remoteDatasource.getPendingInvitesForUser(userId: userId)
//
//        func getPendingGroupInvitesForUser(lastToken: String?, userId: String) async throws ->
//        PaginatedGroupInvites
//        logger.trace("Fetched \(invites.count) invites for user \(userId)")
//        try await localDatasource.removeInvites(userId: userId)
//        logger.trace("Removed old local invites for user \(userId)")
//        try await localDatasource.upsertInvites(userId: userId, invites: invites)
//        logger.trace("Upserted \(invites.count) updated invites for user \(userId)")
//        currentPendingInvites.send(invites)
//    }

//    func refreshInvites() async {
//        refreshInviteTask?.cancel()
//        refreshInviteTask = Task { [weak self] in
//            guard let self else {
//                return
//            }
//            logger.trace("Refreshing all user invitations")
//            do {
//                if Task.isCancelled {
//                    return
//                }
//                let invites = try await getPendingInvitesForUser()
//                if Task.isCancelled {
//                    return
//                }
//                if invites != currentPendingInvites.value {
//                    currentPendingInvites.send(invites)
//                }
//                logger.trace("Invites refreshed with \(invites)")
//            } catch {
//                logger.error(message: "Could not refresh all the user's invitations", error: error)
//            }
//        }
//    }

    func removeCachedInvite(containing inviteToken: String) async {
        logger.trace("Removing current cached invite containing inviteToken \(inviteToken)")
        let newInvites = currentPendingInvites.value.filter { $0.inviteToken != inviteToken }
        currentPendingInvites.send(newInvites)
    }
}

// MARK: - Group

public extension InviteRepository {
    func acceptGroupInvite(with inviteToken: String, and keys: [ItemKey]) async throws {
        logger.trace("Accepting group invite \(inviteToken)")
        let request = AcceptInviteRequest(keys: keys)
        let userId = try await userManager.getActiveUserId()
        try await remoteDatasource.acceptGroupInvite(userId: userId,
                                                     inviteToken: inviteToken,
                                                     request: request)
        logger.trace("Accepted the group invite with token \(inviteToken)")
    }

    func getGroupInviteRecommendations(shareId: String,
                                       query: InviteRecommendationsQuery) async throws -> [Group] {
        logger.trace("Getting invite recommendations for share \(shareId)")
        let userId = try await userManager.getActiveUserId()
        return try await remoteDatasource.getGroupInviteRecommendations(userId: userId)
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
        try await localDatasource.removeUserInvites(userId: userId)
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
        try await localDatasource.removeGroupInvites(userId: userId)
        logger.trace("Removed old local group invites for user \(userId)")
        try await localDatasource.upsertGroupInvites(userId: userId, invites: invites)
        logger.trace("Upserted \(invites.count) group invites for user \(userId)")
        return invites
    }

    func mergeInvites(groupInvites: [GroupInvite], userInvites: [UserInvite]) {
        let invites: [InviteType] = groupInvites.map { .group($0) } + userInvites.map { .user($0) }

        currentPendingInvites.send(invites)
    }
}

//
// async let updateUserInvite = try updateUserInvite()
//
// public protocol LocalInviteDatasourceProtocol: Sendable {
//    // MARK: - User invites
//    func getUserInvites(userId: String) async throws -> [UserInvite]
//    func upsertUserInvites(userId: String, invites: [UserInvite]) async throws
//    // Remove specific invites (e.g after accepting or rejecting an invite)
//    func removeUserInvites(userId: String, invites: [UserInvite]) async throws
//
//    // MARK: - Group invites
//
//    func getGroupInvites(userId: String) async throws -> [GroupInvite]
//    func upsertGroupInvites(userId: String, invites: [GroupInvite]) async throws
//    func removeGroupInvites(userId: String, invites: [GroupInvite]) async throws
//
//    // Re
