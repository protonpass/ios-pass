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

import Core
import Entities

public protocol RemoteShareKeyDatasourceProtocol: Sendable {
    func getKeys(userId: String, shareId: String, pageSize: Int) async throws -> [ShareKey]
}

extension RemoteShareKeyDatasourceProtocol {
    func getKeys(userId: String,
                 shareId: String,
                 pageSize: Int = Constants.Utils.defaultPageSize) async throws -> [ShareKey] {
        try await getKeys(userId: userId, shareId: shareId, pageSize: pageSize)
    }
}

public final class RemoteShareKeyDatasource: RemoteDatasource, RemoteShareKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteShareKeyDatasource {
    func getKeys(userId: String,
                 shareId: String,
                 pageSize: Int = Constants.Utils.defaultPageSize) async throws -> [ShareKey] {
        var keys = [ShareKey]()
        var page = 0
        while true {
            let endpoint = GetShareKeysEndpoint(shareId: shareId,
                                                page: page,
                                                pageSize: pageSize)
            let response = try await exec(userId: userId, endpoint: endpoint)

            keys += response.shareKeys.keys
            if response.shareKeys.total < pageSize {
                break
            } else {
                page += 1
            }
        }
        return keys
    }
}
