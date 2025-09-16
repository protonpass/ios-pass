//
// RemoteGroupDatasource.swift
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

import Entities
import Foundation

public protocol RemoteGroupDatasourceProtocol: Sendable {
    func getGroups(userId: String) async throws -> [Group]
    func getMembers(groupId: String, userId: String) async throws -> [GroupMember]
}

public final class RemoteGroupDatasource: RemoteDatasource, RemoteGroupDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteGroupDatasource {
    func getGroups(userId: String) async throws -> [Group] {
        let endpoint = GetListOfGroupsEndpoint()
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.groups
    }

    func getMembers(groupId: String, userId: String) async throws -> [GroupMember] {
        let endpoint = GetListOfGroupMembersEndpoint(groupId: groupId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.members
    }
}
