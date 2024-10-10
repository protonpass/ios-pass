//
// RemoteInviteDatasource.swift
// Proton Pass - Created on 13/07/2023.
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

import Entities

public protocol RemoteInviteDatasourceProtocol: Sendable {
    func getPendingInvitesForUser(userId: String) async throws -> [UserInvite]
    func acceptInvite(userId: String, inviteToken: String, request: AcceptInviteRequest) async throws -> Bool
    func rejectInvite(userId: String, inviteToken: String) async throws -> Bool
}

public final class RemoteInviteDatasource: RemoteDatasource, RemoteInviteDatasourceProtocol, @unchecked Sendable {}

public extension RemoteInviteDatasource {
    func getPendingInvitesForUser(userId: String) async throws -> [UserInvite] {
        let getSharesEndpoint = GetPendingInviteForUserEndpoint()
        try Task.checkCancellation()
        let getSharesResponse = try await exec(userId: userId, endpoint: getSharesEndpoint)
        return getSharesResponse.invites
    }

    func acceptInvite(userId: String, inviteToken: String, request: AcceptInviteRequest) async throws -> Bool {
        let endpoint = AcceptInviteEndpoint(with: inviteToken, and: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func rejectInvite(userId: String, inviteToken: String) async throws -> Bool {
        let endpoint = RejectInviteEndpoint(with: inviteToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }
}
