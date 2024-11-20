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

public enum InviteeData: Sendable, Equatable {
    case existing(email: String, keys: [ItemKey], role: ShareRole)
    case new(email: String, signature: String, role: ShareRole)
}

extension [InviteeData] {
    func existingUserInvitesRequests(targetType: TargetType, itemId: String?) -> [InviteUserToShareRequest] {
        compactMap {
            if case let .existing(email, keys, role) = $0 {
                return InviteUserToShareRequest(keys: keys,
                                                email: email,
                                                targetType: targetType,
                                                shareRole: role,
                                                itemId: itemId)
            }
            return nil
        }
    }

    func newUserInvitesRequests(targetType: TargetType, itemId: String?) -> [InviteNewUserToShareRequest] {
        compactMap {
            if case let .new(email, signature, role) = $0 {
                return InviteNewUserToShareRequest(email: email,
                                                   targetType: targetType,
                                                   signature: signature,
                                                   shareRole: role,
                                                   itemId: itemId)
            }
            return nil
        }
    }
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

public actor ShareInviteRepository: ShareInviteRepositoryProtocol {
    private let remoteDataSource: any RemoteShareInviteDatasourceProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(remoteDataSource: any RemoteShareInviteDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDataSource = remoteDataSource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }
}

// MARK: - Share Invites

public extension ShareInviteRepository {
    func getAllPendingInvites(shareId: String) async throws -> ShareInvites {
        logger.trace("Getting all pending invites for share \(shareId)")
        do {
            let userId = try await userManager.getActiveUserId()
            let invites = try await remoteDataSource.getPendingInvites(userId: userId, sharedId: shareId)
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
        let newUserInvites = inviteesData.newUserInvitesRequests(targetType: targetType, itemId: itemId)

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
            let promoted = try await remoteDataSource.promoteNewUserInvite(userId: userId,
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
            let sent = try await remoteDataSource.sendInviteReminder(userId: userId,
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
            let deleted = try await remoteDataSource.deleteShareInvite(userId: userId,
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
            let deleted = try await remoteDataSource.deleteShareNewUserInvite(userId: userId,
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
        return try await remoteDataSource.getInviteRecommendations(userId: userId, shareId: shareId, query: query)
    }

    func checkAddresses(shareId: String, emails: [String]) async throws -> [String] {
        let userId = try await userManager.getActiveUserId()
        // The endpoint accepts 10 addresses at max so we check in batch
        return try await withThrowingTaskGroup(of: [String].self, returning: [String].self) { [weak self] group in
            guard let self else { return [] }
            for batch in emails.chunked(into: 10) {
                group.addTask {
                    try await self.remoteDataSource.checkAddresses(userId: userId, shareId: shareId, emails: batch)
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

private extension ShareInviteRepository {
    func sendProtonInvites(shareId: String,
                           requests: [InviteUserToShareRequest]) async throws -> Bool {
        logger.trace("Inviting batch Proton users to share \(shareId)")
        do {
            let request = InviteMultipleUsersToShareRequest(invites: requests)
            let userId = try await userManager.getActiveUserId()
            let inviteStatus = try await remoteDataSource.inviteMultipleProtonUsers(userId: userId,
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
            let inviteStatus = try await remoteDataSource.inviteMultipleExternalUsers(userId: userId,
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
}
