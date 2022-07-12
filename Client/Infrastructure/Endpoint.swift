//
// Endpoint.swift
// Proton Pass - Created on 11/07/2022.
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

import Foundation
import ProtonCore_Networking

protocol Endpoint: Request {
    associatedtype Response: Decodable

    /// We don't necessarily need to construct `URLRequest` object here.
    /// Simply give information to Core by overridding `Request`'s properties like `header`, `parameters`...
    /// But this way seems too verbose and not natural. So we are constructing anyway `URLRequest` for future use.
    /// We'll then derive `Request`'s properties from this `URLRequest` in a default extension of `Endpoint` below.
    var request: URLRequest { get }
}

extension Endpoint {
    var path: String {
        guard let url = self.request.url else {
            assertionFailure("URL should not be nil")
            return ""
        }

        if let query = url.query {
            return url.path + "?" + query
        }

        return url.path
    }

    /// For Proton Pass specific use case, we only have authenticated endpoints
    var isAuth: Bool { true }

    var autoRetry: Bool { true }

    var header: [String: Any] {
        var headers: [String: Any] = [:]
        request.headers.forEach { eachHeader in
            headers[eachHeader.name] = eachHeader.value
        }
        return headers
    }

    /// This properties is used by Core to add `Authorization` & `x-pm-uid` headers
    /// Returning nil here because these info are found in `URLRequest`'s headers
    var authCredential: AuthCredential? { nil }

    /// Is included in `path`, returning nil here.
    var parameters: [String: Any]? { nil }

    var nonDefaultTimeout: TimeInterval? { nil }
}
