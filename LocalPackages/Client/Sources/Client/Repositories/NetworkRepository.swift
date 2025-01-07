//
// NetworkRepository.swift
// Proton Pass - Created on 22/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import ProtonCoreServices

public protocol NetworkRepositoryProtocol: Sendable {
    func revokeCurrentSession(userId: String) async throws
    // periphery:ignore
    func forkSession(userId: String, payload: String?, childClientId: String, independent: Int) async throws
        -> String
}

public actor NetworkRepository: NetworkRepositoryProtocol {
    private let apiServicing: any APIManagerProtocol

    public init(apiServicing: any APIManagerProtocol) {
        self.apiServicing = apiServicing
    }
}

public extension NetworkRepository {
    func revokeCurrentSession(userId: String) async throws {
        _ = try await apiServicing.getApiService(userId: userId).exec(endpoint: RevokeTokenEndpoint())
    }

    func forkSession(userId: String,
                     payload: String?,
                     childClientId: String,
                     independent: Int) async throws -> String {
        let request = ForkSessionRequest(payload: payload, childClientId: childClientId, independent: independent)
        let endpoint = ForkSessionEndpoint(request: request)
        let response = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
        return response.selector
    }
}
