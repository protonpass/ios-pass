//
// RemoteDatasource.swift
// Proton Pass - Created on 05/08/2022.
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

import ProtonCore_Networking
import ProtonCore_Services

public protocol RemoteDatasourceProtocol {
    func getShares() async throws -> [Share]
    func getShareKey(shareId: String, page: Int, pageSize: Int) async throws -> ShareKey
    func createItem(shareId: String, requestBody: CreateItemRequestBody) async throws -> ItemData
}

public final class RemoteDatasource {
    private let authCredential: AuthCredential
    private let apiService: APIService

    public init(authCredential: AuthCredential,
                apiService: APIService) {
        self.authCredential = authCredential
        self.apiService = apiService
    }
}

extension RemoteDatasource: RemoteDatasourceProtocol {
    public func getShares() async throws -> [Share] {
        var shares = [Share]()

        // Fetch the partial shares first
        let getSharesEndpoint = GetSharesEndpoint(credential: authCredential)
        let getSharesResponse = try await apiService.exec(endpoint: getSharesEndpoint)

        // Then fetch full share for each partial share
        try await withThrowingTaskGroup(of: Share.self) { [weak self] group in
            guard let self = self else { return }
            for partialShare in getSharesResponse.shares {
                let getShareDataEndpoint = GetShareDataEndpoint(credential: authCredential,
                                                                shareId: partialShare.shareID)
                group.addTask {
                    let getShareDataResponse =
                    try await self.apiService.exec(endpoint: getShareDataEndpoint)
                    return getShareDataResponse.share
                }
            }

            for try await share in group { shares.append(share) }
        }

        return shares
    }

    public func getShareKey(shareId: String, page: Int, pageSize: Int) async throws -> ShareKey {
        let getShareKeysEndpoint = GetShareKeysEndpoint(credential: authCredential,
                                                        shareId: shareId,
                                                        page: page,
                                                        pageSize: pageSize)
        let getShareKeysResponse = try await apiService.exec(endpoint: getShareKeysEndpoint)
        return getShareKeysResponse.keys
    }

    public func createItem(shareId: String, requestBody: CreateItemRequestBody) async throws -> ItemData {
        let createItemEndpoint = CreateItemEndpoint(credential: authCredential,
                                                    shareId: shareId,
                                                    requestBody: requestBody)
        let createItemResponse = try await apiService.exec(endpoint: createItemEndpoint)
        return createItemResponse.item
    }
}
