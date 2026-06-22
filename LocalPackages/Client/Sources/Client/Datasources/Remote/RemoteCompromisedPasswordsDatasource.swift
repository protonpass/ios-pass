//
// RemoteCompromisedPasswordsDatasource.swift
// Proton Pass - Created on 18/06/2026.
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

import Core
import Entities
import Foundation

enum CompromisedPasswordsNetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case invalidLastChangePayload
}

/// Talks to Proton's public k-anonymity compromised-password service.
///
/// This is a public, unauthenticated external host, so it deliberately bypasses the Proton
/// Only the 6-character SHA-1 prefix is ever sent — the full password/hash never leaves the device.
// sourcery: AutoMockable
public protocol RemoteCompromisedPasswordsDatasourceProtocol: Sendable {
    /// Plain-text UNIX epoch seconds of the most recent change to the corpus.
    func lastChange() async throws -> Int

    /// Conditional range query for an uppercase SHA-1 hex prefix (6 chars). Pass the
    /// previously stored, opaque `etag` to receive `304 Not Modified` when unchanged.
    func query(prefix6: String, etag: String?) async throws -> CompromisedRangeResponse
}

public final class RemoteCompromisedPasswordsDatasource: RemoteCompromisedPasswordsDatasourceProtocol, Sendable {
    private let session: URLSession
    private let userAgent: String
    private let baseURLString: String

    public init(userAgent: String,
                baseURLString: String = Constants.CompromisedPasswords.baseURLEndpoint,
                session: URLSession? = nil) {
        self.userAgent = userAgent
        self.baseURLString = baseURLString
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            // Disable URLSession's own HTTP cache so our explicit If-None-Match / 304
            // handling is what drives conditional behaviour (rather than being absorbed
            // transparently by the URL cache).
            configuration.urlCache = nil
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: configuration)
        }
    }
}

public extension RemoteCompromisedPasswordsDatasource {
    func lastChange() async throws -> Int {
        guard let url = URL(string: "\(baseURLString)/split/sha1/last_change") else {
            throw CompromisedPasswordsNetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CompromisedPasswordsNetworkError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw CompromisedPasswordsNetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
        guard let text = String(data: data, encoding: .utf8),
              let timestamp = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw CompromisedPasswordsNetworkError.invalidLastChangePayload
        }
        return timestamp
    }

    func query(prefix6: String, etag: String?) async throws -> CompromisedRangeResponse {
        let prefix = prefix6.uppercased()
        guard prefix.count == 6 else {
            throw CompromisedPasswordsNetworkError.invalidURL
        }
        let p0 = prefix.prefix(2)
        let p2 = prefix.dropFirst(2).prefix(2)
        let p4 = prefix.dropFirst(4).prefix(2)
        guard let url = URL(string: "\(baseURLString)/split/sha1/\(p0)/\(p2)/\(p4)/\(prefix).gz") else {
            throw CompromisedPasswordsNetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("true", forHTTPHeaderField: "Add-Padding")
        // ETags are opaque: the stored value already carries its quoting, so send it verbatim.
        if let etag, !etag.isEmpty {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CompromisedPasswordsNetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 304:
            return .notModified

        case 200:
            let newEtag = httpResponse.value(forHTTPHeaderField: "ETag")
            let body = try data.gunzipped()
            return .modified(etag: newEtag, body: body)

        default:
            throw CompromisedPasswordsNetworkError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
}
