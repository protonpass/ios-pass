//
// UpdateItemFlagsEndpoint.swift
// Proton Pass - Created on 26/03/2024.
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

import ProtonCoreNetworking

// swiftlint:disable discouraged_optional_boolean

public struct UpdateItemFlagsRequest: Sendable, Encodable {
    private(set) var skipHealthCheck: Bool?
    private(set) var skipWeakPasswordCheck: Bool?
    private(set) var skipCompromisedPasswordCheck: Bool?
    private(set) var skipReusedPasswordCheck: Bool?
    private(set) var skip2FACheck: Bool?

    init(flags: [ItemFlag]) {
        for flag in flags {
            switch flag {
            case let .skipHealthCheck(value):
                skipHealthCheck = value

            case let .skipWeakPasswordCheck(value):
                skipWeakPasswordCheck = value

            case let .skipCompromisedPasswordCheck(value):
                skipCompromisedPasswordCheck = value

            case let .skipReusedPasswordCheck(value):
                skipReusedPasswordCheck = value

            case let .skip2FACheck(value):
                skip2FACheck = value
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case skipHealthCheck = "SkipHealthCheck"
        case skipWeakPasswordCheck = "SkipWeakPasswordCheck"
        case skipCompromisedPasswordCheck = "SkipCompromisedPasswordCheck"
        case skipReusedPasswordCheck = "SkipReusedPasswordCheck"
        case skip2FACheck = "Skip2FACheck"
    }
}

// swiftlint:enable discouraged_optional_boolean

struct UpdateItemFlagsEndpoint: Endpoint {
    typealias Body = UpdateItemFlagsRequest
    typealias Response = UpdateItemResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UpdateItemFlagsRequest?

    init(shareId: String, itemId: String, request: UpdateItemFlagsRequest) {
        debugDescription = "Update item flags"
        path = "/pass/v1/share/\(shareId)/item/\(itemId)/flags"
        method = .put
        body = request
    }
}
