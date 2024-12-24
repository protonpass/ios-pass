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

/// Use `URLSession` to make requests that aren't supported by core modules (e.g multipart)
public protocol ApiServiceLiteProtocol: Sendable {
    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo],
                                       onSendBytes: @escaping (Int) -> Void) async throws -> R

    func download(path: String,
                  userId: String,
                  onDownloadBytes: @escaping (Int) -> Void) async throws -> URL
}

private struct TrackedResult<T: Sendable>: Sendable {
    let session: URLSession
    let value: T
}

public final class ApiServiceLite: NSObject, ApiServiceLiteProtocol, DeinitPrintable {
    private let appVersion: String
    private let doh: any DoHInterface
    private let authManager: any AuthManagerProtocol

    private nonisolated(unsafe) var cancellables = Set<AnyCancellable>()
    private let uploadProgress = PassthroughSubject<TrackedResult<Int64>, Never>()
    private let downloadProgress = PassthroughSubject<TrackedResult<Int64>, Never>()
    private let downloadResult = PassthroughSubject<TrackedResult<URL>, Never>()
    private let sessionError = PassthroughSubject<TrackedResult<Error>, Never>()

    public init(appVersion: String,
                doh: any DoHInterface,
                authManager: any AuthManagerProtocol) {
        self.appVersion = appVersion
        self.doh = doh
        self.authManager = authManager
    }
}

public extension ApiServiceLite {
    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo],
                                       onSendBytes: @escaping (Int) -> Void) async throws -> R {
        let (url, credential) = try getUrlAndCredentials(userId: userId)
        let request = URLRequest(url: url,
                                 path: path,
                                 credential: .init(credential),
                                 infos: infos,
                                 appVersion: appVersion)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

        uploadProgress
            .filterValue(by: session)
            .sink { progress in
                onSendBytes(Int(progress))
            }
            .store(in: &cancellables)

        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(R.self, from: data)
    }

    func download(path: String,
                  userId: String,
                  onDownloadBytes: @escaping (Int) -> Void) async throws -> URL {
        let (url, credential) = try getUrlAndCredentials(userId: userId)
        let request = URLRequest(url: url,
                                 path: path,
                                 credential: .init(credential),
                                 appVersion: appVersion)

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        // Use closure base instead of async version because of URLSession limitation
        // https://forums.developer.apple.com/forums/thread/738541
        return try await withCheckedThrowingContinuation { continuation in
            downloadProgress
                .filterValue(by: session)
                .sink { bytesDownloaded in
                    onDownloadBytes(Int(bytesDownloaded))
                }
                .store(in: &cancellables)

            downloadResult
                .filterValue(by: session)
                .sink { url in
                    continuation.resume(returning: url)
                }
                .store(in: &cancellables)

            sessionError
                .filterValue(by: session)
                .sink { error in
                    continuation.resume(throwing: error)
                }
                .store(in: &cancellables)

            let task = session.downloadTask(with: request)
            task.delegate = self
            task.resume()
        }
    }
}

extension ApiServiceLite: URLSessionDataDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        uploadProgress.send(bytesSent, for: session)
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        downloadResult.send(location, for: session)
    }

    public func urlSession(_ session: URLSession,
                           didBecomeInvalidWithError error: (any Error)?) {
        if let error {
            sessionError.send(error, for: session)
        }
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: (any Error)?) {
        if let error {
            sessionError.send(error, for: session)
        }
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        downloadProgress.send(bytesWritten, for: session)
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

private extension PassthroughSubject where Failure == Never {
    func send<T: Sendable>(_ value: T, for session: URLSession) where Output == TrackedResult<T> {
        send(TrackedResult(session: session, value: value))
    }

    func filterValue<T: Sendable>(by session: URLSession)
        -> AnyPublisher<T, Never> where Output == TrackedResult<T> {
        filter { $0.session == session }
            .map(\.value)
            .eraseToAnyPublisher()
    }
}
