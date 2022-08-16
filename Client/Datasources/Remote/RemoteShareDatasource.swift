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

public protocol RemoteShareDatasourceProtocol {
    func getShares() async throws -> [Share]
    func createVault(request: CreateVaultRequest) async throws -> Share
}

public final class RemoteShareDatasource: BaseRemoteDatasource {}

extension RemoteShareDatasource: RemoteShareDatasourceProtocol {
    public func getShares() async throws -> [Share] {
        var shares = [Share]()

        // Fetch the partial shares first
        let getSharesEndpoint = GetSharesEndpoint(credential: authCredential)
        let getSharesResponse = try await apiService.exec(endpoint: getSharesEndpoint)

        // Then fetch full share for each partial share
        try await withThrowingTaskGroup(of: Share.self) { [weak self] group in
            guard let self = self else { return }
            for partialShare in getSharesResponse.shares {
                let getShareEndpoint = GetShareEndpoint(credential: authCredential,
                                                        shareId: partialShare.shareID)
                group.addTask {
                    let getShareResponse =
                    try await self.apiService.exec(endpoint: getShareEndpoint)
                    return getShareResponse.share
                }
            }

            for try await share in group { shares.append(share) }
        }

        return shares
    }

    public func createVault(request: CreateVaultRequest) async throws -> Share {
        let endpoint = CreateVaultEndpointV2(credential: authCredential,
                                             request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.share
    }
}
