//
// MakeNetworkRequest.swift
// Proton Pass - Created on 09/11/2023.
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
//

import Client
import Core
import ProtonCoreNetworking

public protocol MakeNetworkRequestUseCase {
    func execute(baseUrl: String,
                 path: String,
                 method: HTTPMethod,
                 appVersion: String,
                 sessionId: String,
                 accessToken: String?,
                 body: Encodable?) async throws -> Int
}

public extension MakeNetworkRequestUseCase {
    func callAsFunction(baseUrl: String,
                        path: String,
                        method: HTTPMethod,
                        appVersion: String,
                        sessionId: String,
                        accessToken: String?,
                        body: Encodable?) async throws -> Int {
        try await execute(baseUrl: baseUrl,
                          path: path,
                          method: method,
                          appVersion: appVersion,
                          sessionId: sessionId,
                          accessToken: accessToken,
                          body: body)
    }
}

public final class MakeNetworkRequest: MakeNetworkRequestUseCase {
    private let apiService: ApiServiceLiteProtocol

    public init(apiService: ApiServiceLiteProtocol) {
        self.apiService = apiService
    }

    public func execute(baseUrl: String,
                        path: String,
                        method: HTTPMethod,
                        appVersion: String,
                        sessionId: String,
                        accessToken: String?,
                        body: Encodable?) async throws -> Int {
        let request = try URLUtils.makeUrlRequest(baseUrl: baseUrl,
                                                  path: path,
                                                  method: method,
                                                  appVersion: appVersion,
                                                  sessionId: sessionId,
                                                  accessToken: accessToken,
                                                  body: body)
        return try await apiService.execute(request: request)
    }
}
