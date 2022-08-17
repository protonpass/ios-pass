//
// APIService+ExecEndpoint.swift
// Proton Pass - Created on 12/07/2022.
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

import Combine
import ProtonCore_Networking
import ProtonCore_Services

public extension APIService {
    /// Async variant that can take an `Endpoint`
    func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        try await withCheckedThrowingContinuation { continuation in
            printDebugInfo(endpoint: endpoint)
            exec(route: endpoint) { (task: URLSessionDataTask?, result: Result<E.Response, ResponseError>) in
                printDebugInfo(endpoint: endpoint, task: task, result: result)
                continuation.resume(with: result)
            }
        }
    }
}

private func printDebugInfo<E: Endpoint>(endpoint: E) {
#if DEBUG
    print("==> \(endpoint.method.toString()) \(endpoint.path)")
    print("isAuth: \(endpoint.isAuth)")
    print("authCredential: \(String(describing: endpoint.authCredential))")
    print("header: \(endpoint.header)")
    print("parameters: \(String(describing: endpoint.parameters))")
#endif
}

private func printDebugInfo<E: Endpoint>(endpoint: E,
                                         task: URLSessionDataTask?,
                                         result: Result<E.Response, ResponseError>) {
#if DEBUG
    if let response = task?.response as? HTTPURLResponse {
        print("<== \(response.statusCode) \(endpoint.method.toString()) \(endpoint.path)")
        print("\(response.allHeaderFields)")
        print(result)
    }
#endif
}
