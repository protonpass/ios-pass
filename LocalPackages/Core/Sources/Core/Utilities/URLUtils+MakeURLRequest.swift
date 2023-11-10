//
// URLUtils+MakeURLRequest.swift
// Proton Pass - Created on 10/11/2023.
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

public extension URLUtils {
    // swiftlint:disable:next function_parameter_count
    static func makeUrlRequest(baseUrl: String,
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
