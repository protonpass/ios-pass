//
// RemoteShareDatasource.swift
// Proton Pass - Created on 16/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

// sourcery: AutoMockable
public protocol RemoteShareDatasourceProtocol: Sendable {
    func getShares(userId: String) async throws -> [Share]
    func getShare(shareId: String, userId: String, eventToken: String?) async throws -> Share
    func getUsersLinkedToVaultShare(userId: String, shareId: String, lastToken: String?) async throws
        -> PaginatedUsersLinkedToShare
    func getUsersLinkedToItemShare(userId: String,
                                   shareId: String,
                                   itemId: String,
                                   lastToken: String?) async throws
        -> PaginatedUsersLinkedToShare
    func updateUserSharePermission(userId: String,
                                   shareId: String,
                                   userShareId: String,
                                   request: UserSharePermissionRequest) async throws -> Bool
    func deleteUserShare(userId: String,
                         shareId: String,
                         userShareId: String) async throws -> Bool

    func deleteShare(userId: String, shareId: String) async throws -> Bool

    func createVault(userId: String, request: CreateVaultRequest) async throws -> Share
    func updateVault(userId: String, request: UpdateVaultRequest, shareId: String) async throws -> Share
    func deleteVault(userId: String, shareId: String) async throws
    func transferVaultOwnership(userId: String,
                                vaultShareId: String,
                                request: TransferOwnershipVaultRequest) async throws -> Bool
    func hideUnhideShares(userId: String,
                          sharesToHide: [String],
                          sharesToUnhide: [String]) async throws -> [Share]
}

public extension RemoteShareDatasourceProtocol {
    func getShare(shareId: String, userId: String) async throws -> Share {
        try await getShare(shareId: shareId, userId: userId, eventToken: nil)
    }
}

public final class RemoteShareDatasource: RemoteDatasource, RemoteShareDatasourceProtocol, @unchecked Sendable {}

public extension RemoteShareDatasource {
    func getShare(shareId: String, userId: String, eventToken: String?) async throws -> Share {
        let getShareEndpoint = GetShareEndpoint(for: shareId, eventToken: eventToken)
        let getSharesResponse = try await exec(userId: userId, endpoint: getShareEndpoint)
        return getSharesResponse.share
    }

    func getShares(userId: String) async throws -> [Share] {
        let getSharesEndpoint = GetSharesEndpoint()
        let getSharesResponse = try await exec(userId: userId, endpoint: getSharesEndpoint)
        return getSharesResponse.shares
    }

    func getUsersLinkedToVaultShare(userId: String,
                                    shareId: String,
                                    lastToken: String?) async throws -> PaginatedUsersLinkedToShare {
        let endpoint = GetUsersLinkedToVaultShareEndpoint(for: shareId, lastToken: lastToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response
    }

    func getUsersLinkedToItemShare(userId: String,
                                   shareId: String,
                                   itemId: String,
                                   lastToken: String?) async throws -> PaginatedUsersLinkedToShare {
        let endpoint = GetUsersLinkedToItemShareEndpoint(for: shareId, itemId: itemId, lastToken: lastToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response
    }

    func updateUserSharePermission(userId: String,
                                   shareId: String,
                                   userShareId: String,
                                   request: UserSharePermissionRequest) async throws -> Bool {
        let endpoint = UpdateUserSharePermissionsEndpoint(shareId: shareId,
                                                          userShareId: userShareId,
                                                          request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func deleteUserShare(userId: String,
                         shareId: String,
                         userShareId: String) async throws -> Bool {
        let endpoint = DeleteUserShareEndpoint(shareId: shareId, userShareId: userShareId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func deleteShare(userId: String, shareId: String) async throws -> Bool {
        let endpoint = DeleteShareEndpoint(for: shareId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func createVault(userId: String, request: CreateVaultRequest) async throws -> Share {
        let endpoint = CreateVaultEndpoint(request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.share
    }

    func updateVault(userId: String, request: UpdateVaultRequest, shareId: String) async throws -> Share {
        let endpoint = UpdateVaultEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.share
    }

    func deleteVault(userId: String, shareId: String) async throws {
        let endpoint = DeleteVaultEndpoint(shareId: shareId)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func transferVaultOwnership(userId: String,
                                vaultShareId: String,
                                request: TransferOwnershipVaultRequest) async throws -> Bool {
        let endpoint = TransferOwnershipVaultEndpoint(vaultShareId: vaultShareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func hideUnhideShares(userId: String,
                          sharesToHide: [String],
                          sharesToUnhide: [String]) async throws -> [Share] {
        let endpoint = HideUnhideSharesEndpoint(sharesToHide: sharesToHide,
                                                sharesToUnhide: sharesToUnhide)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.shares
    }
}
