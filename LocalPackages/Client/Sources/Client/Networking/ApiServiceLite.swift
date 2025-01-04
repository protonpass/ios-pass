//
// ApiServiceLite.swift
// Proton Pass - Created on 12/12/2024.
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

@preconcurrency import Combine
import Core
import Entities
import Foundation
@preconcurrency import ProtonCoreDoh
import ProtonCoreNetworking

public enum ProgressEvent<T: Decodable & Sendable>: Sendable {
    case progress(Float)
    case result(T)
}

/// Use `URLSession` to make requests that aren't supported by core modules (e.g multipart)
public protocol ApiServiceLiteProtocol: Sendable {
    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo]) async throws
        -> AsyncThrowingStream<ProgressEvent<R>, any Error>

    func download(path: String, userId: String) async throws
        -> AsyncThrowingStream<ProgressEvent<Data>, any Error>
}

public actor ApiServiceLite: NSObject, ApiServiceLiteProtocol, DeinitPrintable {
    private let session: URLSession
    private let appVersion: String
    private let doh: any DoHInterface
    private let authManager: any AuthManagerProtocol
    private nonisolated(unsafe) var progressObservation: NSKeyValueObservation?

    public init(session: URLSession = .shared,
                appVersion: String,
                doh: any DoHInterface,
                authManager: any AuthManagerProtocol) {
        self.session = session
        self.appVersion = appVersion
        self.doh = doh
        self.authManager = authManager
    }
}

public extension ApiServiceLite {
    func uploadMultipart<R: Decodable & Sendable>(path: String,
                                                  userId: String,
                                                  infos: [MultipartInfo]) async throws
        -> AsyncThrowingStream<ProgressEvent<R>, any Error> {
        let (url, credential) = try getUrlAndCredentials(userId: userId)
        let request = URLRequest(url: url,
                                 path: path,
                                 credential: .init(credential),
                                 infos: infos,
                                 appVersion: appVersion)

        return .init(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: PassError.deallocatedSelf)
                return
            }

            let task = session.dataTask(with: request) { [weak self] data, _, error in
                guard let self else {
                    continuation.finish(throwing: PassError.deallocatedSelf)
                    return
                }
                if let error {
                    continuation.finish(throwing: error)
                } else if let data {
                    do {
                        let response = try JSONDecoder().decode(R.self, from: data)
                        continuation.yield(.result(response))
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                } else {
                    continuation.finish(throwing: PassError.api(.errorOrDataExpected))
                }
            }

            task.resume()
            progressObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
                continuation.yield(.progress(Float(progress.fractionCompleted)))
            }
        }
    }

    func download(path: String, userId: String) async throws
        -> AsyncThrowingStream<ProgressEvent<Data>, any Error> {
        let (url, credential) = try getUrlAndCredentials(userId: userId)
        let request = URLRequest(url: url,
                                 path: path,
                                 credential: .init(credential),
                                 appVersion: appVersion)

        // Use closure base instead of async version because of URLSession limitation
        // https://forums.developer.apple.com/forums/thread/738541
        return .init(bufferingPolicy: .bufferingNewest(1)) { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: PassError.deallocatedSelf)
                return
            }
            let task = session.dataTask(with: request) { data, _, error in
                if let error {
                    continuation.finish(throwing: error)
                } else if let data {
                    continuation.yield(.result(data))
                    continuation.finish()
                } else {
                    continuation.finish(throwing: PassError.api(.errorOrDataExpected))
                }
            }

            task.resume()
            progressObservation = task.progress.observe(\.fractionCompleted) { progress, _ in
                continuation.yield(.progress(Float(progress.fractionCompleted)))
            }
        }
    }
}

private extension ApiServiceLite {
    func getUrlAndCredentials(userId: String) throws -> (URL, AuthCredential) {
        let host = doh.getCurrentlyUsedHostUrl()
        guard let url = URL(string: host) else {
            throw PassError.api(.invalidApiHost(host))
        }

        guard let credential = authManager.getCredential(userId: userId) else {
            throw PassError.api(.noApiServiceLinkedToUserId)
        }

        return (url, credential)
    }
}
