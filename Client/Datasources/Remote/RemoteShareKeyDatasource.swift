//
// RemoteShareKeyDatasource.swift
// Proton Pass - Created on 24/09/2022.
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

public protocol RemoteShareKeyDatasourceProtocol: RemoteDatasourceProtocol {
    func getKeys(shareId: String) async throws -> [PassKey]
}

public extension RemoteShareKeyDatasourceProtocol {
    func getKeys(shareId: String) async throws -> [PassKey] {
        var keys = [PassKey]()
        var page = 0
        while true {
            let endpoint = GetShareKeysEndpoint(credential: authCredential,
                                                shareId: shareId,
                                                page: page,
                                                pageSize: kDefaultPageSize)
            let response = try await apiService.exec(endpoint: endpoint)

            keys += response.shareKeys.keys
            if response.shareKeys.total < kDefaultPageSize {
                break
            } else {
                page += 1
            }
        }
        return keys
    }
}

public final class RemoteShareKeyDatasource: RemoteDatasource, RemoteShareKeyDatasourceProtocol {}
