//
// DefaultRemoteDatasource.swift
// Proton - Created on 29/09/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton.
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

import ProtonCoreNetworking
import ProtonCoreServices

struct FeatureFlagRequest: Request {
    var path: String {
        "/feature/v2/frontend"
    }

    var isAuth: Bool {
        true
    }
}

struct FeatureFlagResponse: Decodable {
    public let code: Int
    public let toggles: [FeatureFlag]
}

public class DefaultRemoteDatasource: RemoteFeatureFlagsProtocol {
    public let apiService: APIService

    public init(apiService: APIService) {
        self.apiService = apiService
    }

    public func getFlags() async throws -> [FeatureFlag] {
        let endpoint = FeatureFlagRequest()
        let response: FeatureFlagResponse = try await apiService.exec(endpoint: endpoint)
        return response.toggles
    }
}

private extension APIService {
    /// Async variant that can take an `Endpoint`
    func exec<T: Decodable>(endpoint: Request) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            perform(request: endpoint) { _, result in
                continuation.resume(with: result)
            }
        }
    }
}
