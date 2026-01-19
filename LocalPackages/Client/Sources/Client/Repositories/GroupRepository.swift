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

private typealias UserID = String

public protocol GroupRepositoryProtocol: Sendable {
    // periphery:ignore
    func getGroups(userId: String) async throws -> [Group]
    func getGroup(userId: String, groupId: String) async throws -> Group
    // periphery:ignore
    func getMembers(groupId: String, userId: String) async throws -> [GroupMember]
    func getGroupsInfos(userId: String) async throws -> [GroupInfo]
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

    func getGroup(userId: String, groupId: String) async throws -> Group {
        let groups = try await getGroups(userId: userId)
        guard let group = groups.first(where: { $0.id == groupId }) else {
            throw PassError.group(.noMatchingGroup(userId: userId, groupId: groupId))
        }
        return group
    }

    func getMembers(groupId: String, userId: String) async throws -> [GroupMember] {
        logger.trace("Fetching members for groupId \(groupId)")
        let members = try await remoteDatasource.getMembers(groupId: groupId, userId: userId)
        logger.info("Found \(members.count) members for groupId \(groupId)")
        return members
    }

    func getGroupsInfos(userId: String) async throws -> [GroupInfo] {
        logger.trace("Getting all group infos for userId \(userId)")

        let groups = try await getGroups(userId: userId)
        return try await withThrowingTaskGroup(of: GroupInfo?.self,
                                               returning: [GroupInfo].self) { taskGroup in
            for group in groups {
                taskGroup.addTask { [weak self] in
                    guard let self else { return nil }
                    // This should fail silently as some people do not have the rights to see group members
                    let members = try? await getMembers(groupId: group.id, userId: userId)
                    return GroupInfo(group: group, members: members)
                }
            }

            var groupInfos = [GroupInfo]()

            for try await groupInfo in taskGroup {
                if let groupInfo {
                    groupInfos.append(groupInfo)
                }
            }
            return groupInfos
        }
    }
}
