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

import Entities
import Foundation
@preconcurrency import ProtonCoreDoh

/// Use `URLSession` to make requests that aren't supported by core modules (e.g multipart)
public protocol ApiServiceLiteProtocol: Sendable {
    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo]) async throws -> R
}

public final class ApiServiceLite: ApiServiceLiteProtocol {
    private let urlSession: URLSession
    private let appVersion: String
    private let doh: any DoHInterface
    private let authManager: any AuthManagerProtocol

    public init(urlSession: URLSession = .shared,
                appVersion: String,
                doh: any DoHInterface,
                authManager: any AuthManagerProtocol) {
        self.urlSession = urlSession
        self.appVersion = appVersion
        self.doh = doh
        self.authManager = authManager
    }
}

public extension ApiServiceLite {
    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo]) async throws -> R {
        let host = doh.getCurrentlyUsedHostUrl()
        guard let url = URL(string: host) else {
            throw PassError.api(.invalidApiHost(host))
        }

        guard let credential = authManager.getCredential(userId: userId) else {
            throw PassError.api(.noApiServiceLinkedToUserId)
        }

        let request = URLRequest(url: url,
                                 path: path,
                                 credential: .init(credential),
                                 infos: infos,
                                 appVersion: appVersion)
        let (data, _) = try await urlSession.data(for: request)
        return try JSONDecoder().decode(R.self, from: data)
    }
}
