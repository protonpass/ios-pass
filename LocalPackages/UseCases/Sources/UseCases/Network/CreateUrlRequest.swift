//
// CreateUrlRequest.swift
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

import Entities
import Foundation
import ProtonCoreNetworking

public protocol CreateUrlRequestUseCase: Sendable {
    func execute(baseUrl: String,
                 path: String,
                 method: HTTPMethod,
                 appVersion: String,
                 sessionId: String,
                 accessToken: String?,
                 body: Encodable?) throws -> URLRequest
}

public extension CreateUrlRequestUseCase {
    func callAsFunction(baseUrl: String,
                        path: String,
                        method: HTTPMethod,
                        appVersion: String,
                        sessionId: String,
                        accessToken: String?,
                        body: Encodable?) throws -> URLRequest {
        try execute(baseUrl: baseUrl,
                    path: path,
                    method: method,
                    appVersion: appVersion,
                    sessionId: sessionId,
                    accessToken: accessToken,
                    body: body)
    }
}

public final class CreateUrlRequest: CreateUrlRequestUseCase {
    public func execute(baseUrl: String,
                        path: String,
                        method: HTTPMethod,
                        appVersion: String,
                        sessionId: String,
                        accessToken: String?,
                        body: Encodable?) throws -> URLRequest {
        guard var url = URL(string: baseUrl) else {
            throw PassError.badUrlString(baseUrl)
        }

        url = if #available(iOS 16.0, *) {
            url.appending(path: path)
        } else {
            url.appendingPathComponent(path)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("true", forHTTPHeaderField: "X-Enforce-UnauthSession")
        request.setValue(appVersion, forHTTPHeaderField: "x-pm-appversion")
        request.setValue(sessionId, forHTTPHeaderField: "x-pm-uid")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}
