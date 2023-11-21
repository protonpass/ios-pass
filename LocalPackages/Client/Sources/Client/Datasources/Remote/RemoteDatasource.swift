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
import ProtonCoreServices

public let kDefaultPageSize = 100

public protocol RemoteDatasourceProtocol {
    func exec<E: Endpoint>(endpoint: E) async throws -> E.Response
    func exec<E: Endpoint>(endpoint: E, files: [String: URL]) async throws -> E.Response
    func execExpectingData(endpoint: some Endpoint) async throws -> DataResponse
}

public class RemoteDatasource: RemoteDatasourceProtocol {
    private let apiService: APIService

    public init(apiService: APIService) {
        self.apiService = apiService
    }

    public func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        try await apiService.exec(endpoint: endpoint)
    }

    public func exec<E: Endpoint>(endpoint: E, files: [String: URL]) async throws -> E.Response {
        try await apiService.exec(endpoint: endpoint, files: files)
    }

    public func execExpectingData(endpoint: some Endpoint) async throws -> DataResponse {
        try await apiService.execExpectingData(endpoint: endpoint)
    }
}
