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

public protocol RemoteShareDatasourceProtocol: RemoteDatasourceProtocol {
    func getShares() async throws -> [Share]
    func getShare(shareId: String) async throws -> Share
    func getShareLinkedUsers(shareId: String) async throws -> [UserShareInfos]
    func getUserInformationForShare(shareId: String, userId: String) async throws -> UserShareInfos
    func updateUserSharePermission(shareId: String,
                                   userId: String,
                                   request: UserSharePermissionRequest) async throws -> Bool
    func deleteUserShare(shareId: String,
                         userId: String) async throws -> Bool

    func deleteShare(shareId: String) async throws -> Bool

    func createVault(request: CreateVaultRequest) async throws -> Share
    func updateVault(request: UpdateVaultRequest, shareId: String) async throws -> Share
    func deleteVault(shareId: String) async throws
    func transferVaultOwnership(vaultShareId: String, request: TransferOwnershipVaultRequest) async throws -> Bool
}

public extension RemoteShareDatasourceProtocol {
    func getShares() async throws -> [Share] {
        let getSharesEndpoint = GetSharesEndpoint()
        let getSharesResponse = try await apiService.exec(endpoint: getSharesEndpoint)
        return getSharesResponse.shares
    }

    func getShare(shareId: String) async throws -> Share {
        let endpoint = GetShareEndpoint(shareId: shareId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.share
    }

    /*
      Get users that have access to the whole vault, or item
      Response:
      ```json
     {
       "Shares": [
         {
           "ShareID": "AF39EF234BB==",
           "UserName": "Leonard Nimoy",
           "UserEmail": "leo@nimoy.com",
           "TargetType": "1",
           "TargetID": "DEFC342CA23==",
           "Permission": "3",
           "ExpireTime": "18332832",
           "CreateTime": "18332832"
         }
       ],
       "Total": "32",
       "Code": 1000
     }
     ```*/
    func getShareLinkedUsers(shareId: String) async throws -> [UserShareInfos] {
        let endpoint = GetShareLinkedUsersEndpoint(for: shareId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.shares
    }

    func getUserInformationForShare(shareId: String, userId: String) async throws -> UserShareInfos {
        let endpoint = GetUserInformationForShareEndpoint(for: shareId, and: userId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.share
    }

    func updateUserSharePermission(shareId: String,
                                   userId: String,
                                   request: UserSharePermissionRequest) async throws -> Bool {
        let endpoint = UpdateUserSharePermissionsEndpoint(shareId: shareId,
                                                          userId: userId,
                                                          request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }

    func deleteUserShare(shareId: String,
                         userId: String) async throws -> Bool {
        let endpoint = DeleteUserShareEndpoint(for: shareId, and: userId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }

    func deleteShare(shareId: String) async throws -> Bool {
        let endpoint = DeleteShareEndpoint(for: shareId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }
}

// MARK: Vaults Utils

public extension RemoteShareDatasourceProtocol {
    func createVault(request: CreateVaultRequest) async throws -> Share {
        let endpoint = CreateVaultEndpoint(request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.share
    }

    func updateVault(request: UpdateVaultRequest, shareId: String) async throws -> Share {
        let endpoint = UpdateVaultEndpoint(shareId: shareId, request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.share
    }

    func deleteVault(shareId: String) async throws {
        let endpoint = DeleteVaultEndpoint(shareId: shareId)
        _ = try await apiService.exec(endpoint: endpoint)
    }

    func transferVaultOwnership(vaultShareId: String,
                                request: TransferOwnershipVaultRequest) async throws -> Bool {
        let endpoint = TransferOwnershipVaultEndpoint(vaultShareId: vaultShareId, request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.isSuccessful
    }
}

public final class RemoteShareDatasource: RemoteDatasource, RemoteShareDatasourceProtocol {}
