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
    var currentPendingInvites: CurrentValueSubject<[Invite], Never> { get }

    func loadLocalInvites(userId: String) async throws
    func acceptInvite(userId: String, invite: Invite, keys: [ItemKey]) async throws -> Share?

    @discardableResult
    func rejectInvite(userId: String, invite: Invite) async throws -> Bool
    func refreshAllInvites(userId: String) async throws
    func refreshSpecificInvites(userId: String, refreshInviteType: RefreshInviteType) async throws
    func removeCachedInvite(containing inviteToken: String) async
    func sendNewShareInvites(userId: String,
                             shareId: String,
                             newShareInvites: [ShareNewUserInvite]) async throws
}

// sourcery: AutoMockable
public protocol ShareInviteRepositoryProtocol: Sendable {
    func getAllPendingInvites(userId: String, shareId: String) async throws -> ShareInvites

    func sendInvites(userId: String,
                     shareId: String,
                     itemId: String?,
                     inviteesData: [InviteeData],
                     targetType: TargetType) async throws -> Bool

    func promoteNewUserInvite(userId: String,
                              shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool

    @discardableResult
    func sendInviteReminder(userId: String, shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool

    @discardableResult
    func deleteNewUserInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool

    func getInviteRecommendations(userId: String,
                                  shareId: String,
                                  query: InviteRecommendationsQuery) async throws -> InviteRecommendations

    func getSuggestedInvite(userId: String,
                            shareId: String,
                            email: String?) async throws -> [InviteSuggestion]
    func getOrganisationInviteRecommendations(userId: String,
                                              shareId: String,
                                              query: InviteRecommendationsQuery) async throws
        -> OrganizationInviteRecommendations

    func checkAddresses(userId: String, shareId: String, emails: [String]) async throws -> [String]
}

// sourcery: AutoMockable
public typealias FullInviteRepositoryProtocol = InviteRepositoryProtocol & ShareInviteRepositoryProtocol

public actor InviteRepository: FullInviteRepositoryProtocol {
    private let remoteDatasource: any RemoteInviteDatasourceProtocol
    private let localDatasource: any LocalInviteDatasourceProtocol
    private let logger: Logger

    public nonisolated let currentPendingInvites: CurrentValueSubject<[Invite], Never> = .init([])

    public init(remoteDatasource: any RemoteInviteDatasourceProtocol,
                localDatasource: any LocalInviteDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        logger = .init(manager: logManager)
    }
}

public extension InviteRepository {
    func loadLocalInvites(userId: String) async throws {
        async let getUserInvites = try localDatasource.getUserInvites(userId: userId)
        async let getGroupInvites = try localDatasource.getGroupInvites(userId: userId)

        let (groupInvites, userInvites) = try await (getGroupInvites, getUserInvites)
        updateCurrentInvites(groupInvites: groupInvites, userInvites: userInvites)
    }

    func acceptInvite(userId: String, invite: Invite, keys: [ItemKey]) async throws -> Share? {
        let inviteToken = invite.inviteToken
        logger.trace("Accepting invite \(inviteToken)")
        let request = AcceptInviteRequest(keys: keys)

        do {
            switch invite {
            case .user:
                logger.trace("Accepting user invite with token \(inviteToken)")
                let share = try await remoteDatasource.acceptInvite(userId: userId,
                                                                    inviteToken: inviteToken,
                                                                    request: request)
                logger.trace("Accepted user invite with token \(inviteToken)")
                return share
            case .group:
                logger.trace("Accepting group invite with token \(inviteToken)")
                _ = try await remoteDatasource.acceptGroupInvite(userId: userId,
                                                                 inviteToken: inviteToken,
                                                                 request: request)
                logger.trace("Accepted group invite with token \(inviteToken)")
                return nil
            }
        } catch {
            logger.warning("Failed to accept invite \(inviteToken)")
            try await removeLocalOutdatedInvite(userId: userId, error: error, invite: invite)
            throw error
        }
    }

    func rejectInvite(userId: String, invite: Invite) async throws -> Bool {
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
                logger.trace("Group invite rejection status \(rejectedStatus)")
            }
            return rejectedStatus
        } catch {
            logger.warning("Failed to reject invite \(inviteToken)")
            try await removeLocalOutdatedInvite(userId: userId, error: error, invite: invite)
            throw error
        }
    }

    func refreshAllInvites(userId: String) async throws {
        let userInvites = try await updateUserInvite(userId)
        ///  The following should fail silently as only org admins have the right to fetch group invites
        let groupInvites = try? await updateGroupInvite(userId)

        updateCurrentInvites(groupInvites: groupInvites ?? [], userInvites: userInvites)
    }

    func refreshSpecificInvites(userId: String, refreshInviteType: RefreshInviteType) async throws {
        var groupInvites = [GroupInvite]()
        var userInvites = [UserInvite]()
        switch refreshInviteType {
        case let .group(token):
            groupInvites = await (try? updateGroupInvite(userId, eventToken: token)) ?? []
            userInvites = try await localDatasource.getUserInvites(userId: userId)
        case let .user(token):
            groupInvites = try await localDatasource.getGroupInvites(userId: userId)
            userInvites = try await updateUserInvite(userId, eventToken: token)
        }

        updateCurrentInvites(groupInvites: groupInvites, userInvites: userInvites)
    }

    func removeCachedInvite(containing inviteToken: String) async {
        logger.trace("Removing current cached invite containing inviteToken \(inviteToken)")
        let newInvites = currentPendingInvites.value.filter { $0.inviteToken != inviteToken }
        currentPendingInvites.send(newInvites)
    }

    func sendNewShareInvites(userId: String,
                             shareId: String,
                             newShareInvites: [ShareNewUserInvite]) async throws {
        let requests = newShareInvites.map(\.toInviteNewUserToShareRequest)
        _ = try await sendExternalInvites(userId: userId, shareId: shareId, requests: requests)
    }
}

// MARK: - Shares

public extension InviteRepository {
    func getAllPendingInvites(userId: String, shareId: String) async throws -> ShareInvites {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
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

    func sendInvites(userId: String,
                     shareId: String,
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
            return try await sendProtonInvites(userId: userId, shareId: shareId, requests: userInvites)
        } else if userInvites.isEmpty, !newUserInvites.isEmpty {
            return try await sendExternalInvites(userId: userId, shareId: shareId, requests: newUserInvites)
        } else {
            async let invites = sendProtonInvites(userId: userId, shareId: shareId, requests: userInvites)
            async let newInvites = sendExternalInvites(userId: userId, shareId: shareId, requests: newUserInvites)

            let (invitesSuccess, newInvitesSuccess) = try await (invites, newInvites)
            return invitesSuccess && newInvitesSuccess
        }
    }

    func promoteNewUserInvite(userId: String,
                              shareId: String,
                              inviteId: String,
                              keys: [ItemKey]) async throws -> Bool {
        logger.trace("Promoting new user invite \(inviteId) for share \(shareId)")
        do {
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

    func sendInviteReminder(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Sending reminder for share \(shareId) invite \(inviteId)")
        do {
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

    func deleteInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Deleting invite \(inviteId) for share \(shareId)")
        do {
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

    func deleteNewUserInvite(userId: String, shareId: String, inviteId: String) async throws -> Bool {
        logger.trace("Deleting new user invite \(inviteId) for share \(shareId)")
        do {
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

    func getInviteRecommendations(userId: String,
                                  shareId: String,
                                  query: InviteRecommendationsQuery) async throws -> InviteRecommendations {
        logger.trace("Getting invite recommendations for share \(shareId)")
        return try await remoteDatasource.getInviteRecommendations(userId: userId, shareId: shareId, query: query)
    }

    func getSuggestedInvite(userId: String,
                            shareId: String,
                            email: String?) async throws -> [InviteSuggestion] {
        logger.trace("Getting recent invite recommendations for share \(shareId)")
        return try await remoteDatasource.getInviteSuggestions(userId: userId,
                                                               shareId: shareId,
                                                               email: email)
    }

    func getOrganisationInviteRecommendations(userId: String,
                                              shareId: String,
                                              query: InviteRecommendationsQuery) async throws
        -> OrganizationInviteRecommendations {
        logger.trace("Getting organization invite recommendations for share \(shareId)")
        return try await remoteDatasource.getOrganizationRecommendations(userId: userId,
                                                                         shareId: shareId,
                                                                         query: query)
    }

    func checkAddresses(userId: String, shareId: String, emails: [String]) async throws -> [String] {
        // The endpoint accepts 10 addresses at max so we check in batch
        try await withThrowingTaskGroup(of: [String].self, returning: [String].self) { [weak self] group in
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
    func sendProtonInvites(userId: String,
                           shareId: String,
                           requests: [InviteUserToShareRequest]) async throws -> Bool {
        logger.trace("Inviting batch Proton users to share \(shareId)")
        do {
            let request = InviteMultipleUsersToShareRequest(invites: requests)
            let inviteStatus = try await remoteDatasource.inviteExistingUsers(userId: userId,
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

    func sendExternalInvites(userId: String,
                             shareId: String,
                             requests: [InviteNewUserToShareRequest]) async throws -> Bool {
        logger.trace("Inviting multiple external users to share \(shareId)")
        do {
            let request = InviteMultipleNewUsersToShareRequest(newUserInvites: requests)
            let inviteStatus = try await remoteDatasource.inviteNewUsers(userId: userId,
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

    func updateUserInvite(_ userId: String, eventToken: String? = nil) async throws -> [UserInvite] {
        logger.trace("Refreshing user invites for user \(userId)")
        let invites = try await remoteDatasource.getPendingInvitesForUser(userId: userId, eventToken: eventToken)
        logger.trace("Fetched \(invites.count) user invites for user \(userId)")
        try await localDatasource.removeAllUserInvites(userId: userId)
        logger.trace("Removed old local user invites for user \(userId)")
        try await localDatasource.upsertUserInvites(userId: userId, invites: invites)
        logger.trace("Upserted \(invites.count) user invites for user \(userId)")
        return invites
    }

    func updateGroupInvite(_ userId: String, eventToken: String? = nil) async throws -> [GroupInvite] {
        logger.trace("Refreshing group invites for user \(userId)")
        var invites = [GroupInvite]()
        var lastToken: String?
        while true {
            let results = try await remoteDatasource.getPendingGroupInvitesForUser(lastToken: lastToken,
                                                                                   userId: userId,
                                                                                   eventToken: eventToken)
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

    func updateCurrentInvites(groupInvites: [GroupInvite], userInvites: [UserInvite]) {
        let invites: [Invite] = groupInvites.map { .group($0) } + userInvites.map { .user($0) }

        currentPendingInvites.send(invites)
    }

    func removeLocalOutdatedInvite(userId: String, error: Error, invite: Invite) async throws {
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

public enum RefreshInviteType: Sendable {
    case user(token: String)
    case group(token: String)
}

private extension ShareNewUserInvite {
    var toInviteNewUserToShareRequest: InviteNewUserToShareRequest {
        InviteNewUserToShareRequest(email: invitedEmail,
                                    targetType: shareType,
                                    signature: signature,
                                    shareRole: shareRole,
                                    itemId: shareType == .item ? targetID : nil)
    }
}
