//
// RemoteDatasource.swift
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
import ProtonCoreNetworking
import ProtonCoreServices

public class RemoteDatasource: @unchecked Sendable {
    private let apiServicing: any APIManagerProtocol

    public init(apiServicing: some APIManagerProtocol) {
        self.apiServicing = apiServicing
    }

    func exec<E: Endpoint>(userId: String, endpoint: E) async throws -> E.Response {
        try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
    }

    func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        try await apiServicing.getUnauthApiService().exec(endpoint: endpoint)
    }

    func execExpectingData(userId: String, endpoint: some Endpoint) async throws -> DataResponse {
        try await apiServicing.getApiService(userId: userId).execExpectingData(endpoint: endpoint)
    }
}
