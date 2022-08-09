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
    associatedtype Response: Decodable
    associatedtype Body: Encodable

    var body: Body? { get }
}

public extension Endpoint {
    var isAuth: Bool { true }
    var autoRetry: Bool { true }
    var authCredential: AuthCredential? { nil }
    var method: HTTPMethod { .get }
    var body: Body? { nil }
    var nonDefaultTimeout: TimeInterval? { nil }
    var parameters: [String: Any]? {
        guard let body = body,
              let data = try? JSONEncoder().encode(body) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data,
                                                  options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
