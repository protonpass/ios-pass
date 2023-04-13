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
            NetworkDebugger.printDebugInfo(endpoint: endpoint)
            perform(request: endpoint) { task, result in
                NetworkDebugger.printDebugInfo(endpoint: endpoint, task: task, result: result)
                continuation.resume(with: result)
            }
        }
    }

    /// As of the moment of writting this, `APIService` doesn't support `perform` function
    /// that returns `Data`. So we make `Decodable` request and expect an error to get the actual `Data`
    /// from the error object.
    func execExpectingData<E: Endpoint>(endpoint: E) async throws -> DataResponse {
        try await withCheckedThrowingContinuation { continuation in
            NetworkDebugger.printDebugInfo(endpoint: endpoint)

            perform(request: endpoint) { task, result in
                NetworkDebugger.printDebugInfo(endpoint: endpoint, task: task, result: result)

                guard let httpResponse = task?.response as? HTTPURLResponse else {
                    continuation.resume(throwing: PPClientError.notHttpResponse)
                    return
                }

                switch result {
                case .success:
                    continuation.resume(throwing: PPClientError.errorExpected)

                case .failure(let error):
                    if let responseError = error.underlyingError as? SessionResponseError,
                       case let .responseBodyIsNotADecodableObject(body, _) = responseError {
                        continuation.resume(returning: .init(httpResponse: httpResponse,
                                                             protonCode: error.responseCode,
                                                             data: body))
                        return
                    }
                    continuation.resume(throwing: PPClientError.unexpectedError)
                }
            }
        }
    }
}

private enum NetworkDebugger {
    private static func shouldDebugNetworkTraffic() -> Bool {
        ProcessInfo.processInfo.environment["me.proton.pass.NetworkDebug"] == "1"
    }

    static func printDebugInfo<E: Endpoint>(endpoint: E) {
        guard shouldDebugNetworkTraffic() else { return }
        print("\n[\(endpoint.debugDescription)]")
        print("==> \(endpoint.method.rawValue) \(endpoint.path)")
        print("Authenticated endpoint: \(endpoint.isAuth)")

        if let authCredential = endpoint.authCredential {
            print("Auth credential:")
            dump(authCredential)
        }

        if !endpoint.header.isEmpty {
            print("Headers:")
            for (key, value) in endpoint.header {
                print("   \(key): \(value)")
            }
        }

        if let parameters = endpoint.parameters,
           !parameters.isEmpty {
            print("Parameters:")
            for(key, value) in parameters {
                print("   \(key): \(value)")
            }
        }
    }

    static func printDebugInfo<E: Endpoint>(endpoint: E,
                                            task: URLSessionDataTask?,
                                            result: Result<E.Response, ResponseError>) {
        guard shouldDebugNetworkTraffic(),
              let response = task?.response as? HTTPURLResponse else { return }

        let urlString = task?.originalRequest?.url?.absoluteString ?? "originalRequest is null"
        print("\n[\(endpoint.debugDescription)]")
        print("<== \(response.statusCode) \(endpoint.method.rawValue) \(urlString)")

        if !response.allHeaderFields.isEmpty {
            print("Headers:")
            for (key, value) in response.allHeaderFields {
                print("   \(key): \(value)")
            }
        }

        switch result {
        case .success(let object):
            print("Success:")
            dump(object)
        case .failure(let error):
            print("Failure:")
            dump(error)
        }
    }
}
