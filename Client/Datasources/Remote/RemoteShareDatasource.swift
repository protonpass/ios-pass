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

import Foundation

public protocol RemoteShareDatasourceProtocol: RemoteDatasourceProtocol {
    func getShares() async throws -> [Share]
    func getShare(shareId: String) async throws -> Share
    func createVault(request: CreateVaultRequest) async throws -> Share
    func updateVault(request: UpdateVaultRequest, shareId: String) async throws -> Share
    func deleteVault(shareId: String) async throws
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
}

public final class RemoteShareDatasource: RemoteDatasource, RemoteShareDatasourceProtocol {}
