//
// RemotePublicKeyDatasource.swift
// Proton Pass - Created on 17/08/2022.
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

import ProtonCore_Services

/// Special repository that doesn't conform to `BaseRemoteDatasourceProtocol`
/// because it doesn't need `AuthCredential`
public protocol RemotePublicKeyDatasourceProtocol {
    func getPublicKeys(email: String) async throws -> [PublicKey]
}

public struct RemotePublicKeyDatasource: RemotePublicKeyDatasourceProtocol {
    public let apiService: APIService

    public init(apiService: APIService) {
        self.apiService = apiService
    }

    public func getPublicKeys(email: String) async throws -> [PublicKey] {
        let endpoint = GetPublicKeysEndpoint(email: email)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.keys
    }
}
