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
import Foundation
import ProtonCoreServices

public protocol RemoteInviteDatasourceProtocol {
    func getPendingInvitesForUser() async throws -> [UserInvite]
    func acceptInvite(inviteToken: String, request: AcceptInviteRequest) async throws -> Bool
    func rejectInvite(inviteToken: String) async throws -> Bool
}

public final class RemoteInviteDatasource: RemoteDatasource, RemoteInviteDatasourceProtocol {}

public extension RemoteInviteDatasource {
    func getPendingInvitesForUser() async throws -> [UserInvite] {
        let getSharesEndpoint = GetPendingInviteForUserEndpoint()
        let getSharesResponse = try await exec(endpoint: getSharesEndpoint)
        return getSharesResponse.invites
    }

    func acceptInvite(inviteToken: String, request: AcceptInviteRequest) async throws -> Bool {
        let endpoint = AcceptInviteEndpoint(with: inviteToken, and: request)
        let response = try await exec(endpoint: endpoint)
        return response.isSuccessful
    }

    func rejectInvite(inviteToken: String) async throws -> Bool {
        let endpoint = RejectInviteEndpoint(with: inviteToken)
        let response = try await exec(endpoint: endpoint)
        return response.isSuccessful
    }
}
