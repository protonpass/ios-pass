//
// GroupRepository.swift
// Proton Pass - Created on 30/07/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public protocol GroupRepositoryProtocol: Sendable {
    /// Get from local, refresh if not exist
    /// Could be nil if the user is not in business plan
    func getGroups(userId: String) async throws -> [Group]
    func getMembers(groupId: String, userId: String) async throws -> [GroupMember]
}

public actor GroupRepository: GroupRepositoryProtocol {
    private let remoteDatasource: any RemoteGroupDatasourceProtocol
    private let logger: Logger

    public init(remoteDatasource: any RemoteGroupDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        logger = .init(manager: logManager)
    }
}

public extension GroupRepository {
    func getGroups(userId: String) async throws -> [Group] {
        logger.trace("Getting all groups for userId \(userId)")
        let groups = try await remoteDatasource.getGroups(userId: userId)
        logger.info("Found \(groups.count) groups for userId \(userId)")
        return groups
    }

    func getMembers(groupId: String, userId: String) async throws -> [GroupMember] {
        logger.trace("Fetching members for groupId \(groupId)")
        let members = try await remoteDatasource.getMembers(groupId: groupId, userId: userId)
        logger.info("Found \(members.count) members for groupId \(groupId)")
        return members
    }

//    func refreshOrganization(userId: String) async throws -> Organization? {
//        logger.trace("Refreshing organization for userId \(userId)")
//        if let organization = try await remoteDatasource.getOrganization(userId: userId) {
//            logger.trace("Refreshed organization for userId \(userId). Upserting to local database.")
//            try await localDatasource.upsertOrganization(organization, userId: userId)
//            logger.trace("Refreshed organization for userId \(userId). Upserted to local database.")
//            return organization
//        }
//        logger.info("Refreshed and found no organization for suserId \(userId)")
//        return nil
//    }
}
