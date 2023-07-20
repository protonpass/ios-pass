//
// RemoteShareInviteDatasource.swift
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

public protocol RemoteShareInviteDatasourceProtocol: RemoteDatasourceProtocol {
    func getPendingInvitesForShare(sharedId: String) async throws -> [ShareInvite]
    func inviteUser(shareId: String, request: InviteUserToShareRequest) async throws -> Bool
    func sendInviteReminderToUser(shareId: String, userId: String) async throws -> Bool
    func deleteShareUserInvite(shareId: String, userId: String) async throws -> Bool
}

public extension RemoteShareInviteDatasourceProtocol {
    func getPendingInvitesForShare(sharedId: String) async throws -> [ShareInvite] {
        let getSharesEndpoint = GetPendingInvitesforShareEndpoint(for: sharedId)
        let getSharesResponse = try await apiService.exec(endpoint: getSharesEndpoint)
        return getSharesResponse.invites
    }

    func inviteUser(shareId: String, request: InviteUserToShareRequest) async throws -> Bool {
        let endpoint = InviteUserToShareEndpoint(for: shareId, with: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }

    func sendInviteReminderToUser(shareId: String, userId: String) async throws -> Bool {
        let endpoint = SendInviteReminderToUserEndpoint(for: shareId, with: userId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }

    func deleteShareUserInvite(shareId: String, userId: String) async throws -> Bool {
        let endpoint = DeleteInviteEndpoint(for: shareId, with: userId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }
}

public final class RemoteShareInviteDatasource: RemoteDatasource, RemoteShareInviteDatasourceProtocol {}
