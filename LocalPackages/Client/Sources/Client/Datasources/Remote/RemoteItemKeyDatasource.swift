//
// RemoteItemKeyDatasource.swift
// Proton Pass - Created on 24/02/2023.
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

public protocol RemoteItemKeyDatasourceProtocol: Sendable {
    func getLatestKey(userId: String, shareId: String, itemId: String) async throws -> ItemKey
    func getAllKeys(userId: String, shareId: String, itemId: String) async throws -> [ItemKey]
}

public final class RemoteItemKeyDatasource: RemoteDatasource, RemoteItemKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteItemKeyDatasource {
    func getLatestKey(userId: String, shareId: String, itemId: String) async throws -> ItemKey {
        let endpoint = GetLatestItemKeyEndpoint(shareId: shareId, itemId: itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.key
    }

    func getAllKeys(userId: String, shareId: String, itemId: String) async throws -> [ItemKey] {
        let endpoint = GetItemKeysEndpoint(shareId: shareId, itemId: itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.keys.keys
    }
}
