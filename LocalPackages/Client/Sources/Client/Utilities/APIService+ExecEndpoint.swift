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

import Entities
import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

actor SessionTask {
    private var state: State = .ready

    func cancel() {
        if case let .executing(task) = state {
            task.cancel()
        }
        state = .cancelled
    }

    func setTask(_ task: URLSessionDataTask) {
        if case .cancelled = state {
            return
        }
        state = .executing(task)
    }

    private enum State {
        case ready
        case executing(URLSessionDataTask)
        case cancelled
    }
}

extension APIService {
    func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        let sessionTask = SessionTask()
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    NetworkDebugger.printDebugInfo(endpoint: endpoint)
                    perform(request: endpoint,
                            onDataTaskCreated: { task in
                                Task {
                                    await sessionTask.setTask(task)
                                }
                            }, decodableCompletion: { task, result in
                                NetworkDebugger.printDebugInfo(endpoint: endpoint, task: task, result: result)
                                continuation.resume(with: result)
                            })
                }
            } onCancel: {
                Task { await sessionTask.cancel() }
            }
        } catch URLError.cancelled {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            } else {
                throw error
            }
        }
    }

    /// Execute an async request with attached files
    /// - Parameters:
    ///   - endpoint: The `Endpoint` to reach
    ///   - files: Files to send in the format of `[String: URL]`
    /// - Returns: The endpoint response of type `Response` or `throws` an `Error`
    func exec<E: Endpoint>(endpoint: E, files: [String: URL]) async throws -> E.Response {
        let progress: ProgressCompletion = { progress in
            if NetworkDebugger.shouldDebugNetworkTraffic() {
                print("Upload progress \(progress.fractionCompleted) for \(endpoint.path)")
            }
        }

        return try await withCheckedThrowingContinuation { continuation in
            NetworkDebugger.printDebugInfo(endpoint: endpoint)
            performUpload(request: endpoint, files: files, uploadProgress: progress) { task, result in
                NetworkDebugger.printDebugInfo(endpoint: endpoint,
                                               task: task,
                                               result: result)
                continuation.resume(with: result)
            }
        }
    }

    /// As of the moment of writting this, `APIService` doesn't support `perform` function
    /// that returns `Data`. So we make `Decodable` request and expect an error to get the actual `Data`
    /// from the error object.
    func execExpectingData(endpoint: some Endpoint) async throws -> DataResponse {
        let sessionTask = SessionTask()
        do {
            return try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    NetworkDebugger.printDebugInfo(endpoint: endpoint)

                    perform(request: endpoint,
                            onDataTaskCreated: { task in
                                Task {
                                    await sessionTask.setTask(task)
                                }
                            },
                            decodableCompletion: { task, result in
                                NetworkDebugger.printDebugInfo(endpoint: endpoint, task: task, result: result)
                                switch result {
                                case .success:
                                    continuation.resume(throwing: PassError.errorExpected)

                                case let .failure(error):
                                    if let responseError = error.underlyingError as? SessionResponseError,
                                       case let .responseBodyIsNotADecodableObject(body, _) = responseError {
                                        continuation.resume(returning: .init(httpCode: error.httpCode,
                                                                             protonCode: error.responseCode,
                                                                             data: body))
                                        return
                                    }
                                    continuation.resume(throwing: PassError.unexpectedError)
                                }
                            })
                }
            } onCancel: {
                Task { await sessionTask.cancel() }
            }
        } catch URLError.cancelled {
            throw CancellationError()
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            } else {
                throw error
            }
        }
    }
}

private enum NetworkDebugger {
    static func shouldDebugNetworkTraffic() -> Bool {
        ProcessInfo.processInfo.environment["me.proton.pass.NetworkDebug"] == "1"
    }

    static func printDebugInfo(endpoint: some Endpoint) {
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
            for (key, value) in parameters {
                print("   \(key): \(value)")
            }
        }
    }

    static func printDebugInfo<E: Endpoint>(endpoint: E,
                                            task: URLSessionDataTask?,
                                            result: Result<E.Response, some Error>) {
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
        case let .success(object):
            print("Success:")
            dump(object)
        case let .failure(error):
            print("Failure:")
            dump(error)
            if let responseError = error as? ResponseError,
               let underError = responseError.underlyingError as? SessionResponseError,
               case let .responseBodyIsNotADecodableObject(body, _) = underError,
               let body {
                print(String(data: body, encoding: .utf8))
            }
        }
    }
}
