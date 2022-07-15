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

public protocol Endpoint: Request {
    /// `Decodable` should be enough but Core's functions need`Codable`
    associatedtype Response: Codable

    static var baseHeaders: [String: String] { get }
}

public extension Endpoint {
    static var baseHeaders: [String: String] {
        [
            "x-pm-appversion": Bundle.main.appVersion,
            "Accept": "application/vnd.protonmail.v1+json",
            "Content-Type": "application/json;charset=utf-8"
        ]
    }
}

public extension Endpoint {
    var isAuth: Bool { true }
    var autoRetry: Bool { true }
    var header: [String: Any] { Self.baseHeaders }
    var authCredential: AuthCredential? { nil }
    var method: HTTPMethod { .get }
    var parameters: [String: Any]? { nil }
    var nonDefaultTimeout: TimeInterval? { nil }
}
