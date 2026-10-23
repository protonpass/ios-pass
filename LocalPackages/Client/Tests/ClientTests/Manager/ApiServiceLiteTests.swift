//
// ApiServiceLiteTests.swift
// Proton Pass - Created on 21/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import Client
import ClientMocks
import CoreMocks
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking
import Testing

@Suite(.tags(.manager))
struct ApiServiceLiteTests {
    private let userId = String.random()
    private let sut: ApiServiceLite

    init() {
        let symmetricKeyProvider = NonSendableSymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = SymmetricKey.random()
        let authManager = AuthManager(keychain: InMemoryKeychainMock(),
                                      symmetricKeyProvider: symmetricKeyProvider,
                                      module: .hostApp,
                                      logManager: LogManagerProtocolMock())
        authManager.setUp()
        authManager.onSessionObtaining(credential: Credential(AuthCredential.random(userId: userId)))

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StatusCodeURLProtocol.self]
        sut = ApiServiceLite(session: URLSession(configuration: configuration),
                             appVersion: "ios-pass@1.0.0",
                             doh: ProtonPassDoHMock(),
                             authManager: authManager)
    }

    @Test func `a successful download returns the response body`() async throws {
        let stream = try await sut.download(path: StatusCodeURLProtocol.path(200), userId: userId)

        #expect(try await finalResult(of: stream) == StatusCodeURLProtocol.body)
    }

    @Test(arguments: [401, 422, 500])
    func `a download with an error status throws instead of returning the error body`(statusCode: Int) async throws {
        let stream = try await sut.download(path: StatusCodeURLProtocol.path(statusCode), userId: userId)

        await #expect(throws: PassError.api(.unexpectedStatusCode(statusCode))) {
            try await finalResult(of: stream)
        }
    }

    @Test func `a successful upload decodes the response body`() async throws {
        let stream: AsyncThrowingStream<ProgressEvent<CodeResponse>, any Error> =
            try await sut.uploadMultipart(path: StatusCodeURLProtocol.path(200),
                                          userId: userId,
                                          infos: [.init(name: "File", data: Data("chunk".utf8))])

        #expect(try await finalResult(of: stream)?.code == 1_000)
    }

    @Test(arguments: [401, 422, 500])
    func `an upload with an error status throws instead of decoding the error body`(statusCode: Int) async throws {
        let stream: AsyncThrowingStream<ProgressEvent<CodeResponse>, any Error> =
            try await sut.uploadMultipart(path: StatusCodeURLProtocol.path(statusCode),
                                          userId: userId,
                                          infos: [.init(name: "File", data: Data("chunk".utf8))])

        await #expect(throws: PassError.api(.unexpectedStatusCode(statusCode))) {
            try await finalResult(of: stream)
        }
    }
}

private struct CodeResponse: Decodable {
    let code: Int

    enum CodingKeys: String, CodingKey {
        case code = "Code"
    }
}

private func finalResult<T>(of stream: AsyncThrowingStream<ProgressEvent<T>, any Error>) async throws -> T? {
    var result: T?
    for try await event in stream {
        if case let .result(value) = event {
            result = value
        }
    }
    return result
}

/// Answers every request with the status code encoded as the last path component, so parallel
/// tests need no shared state. The body decodes as a valid response on purpose: an error status
/// must be rejected even when its body looks usable.
private final class StatusCodeURLProtocol: URLProtocol {
    static let body = Data(#"{"Code":1000}"#.utf8)

    static func path(_ statusCode: Int) -> String {
        "/stub/\(statusCode)"
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let statusCode = Int(url.lastPathComponent),
              let response = HTTPURLResponse(url: url,
                                             statusCode: statusCode,
                                             httpVersion: nil,
                                             headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
