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

public struct UpdateItemFlagsRequest: Sendable, Encodable {
    // swiftlint:disable:next discouraged_optional_boolean
    private(set) var skipHealthCheck: Bool?

    init(flags: [ItemFlag]) {
        for flag in flags {
            switch flag {
            case let .skipHealthCheck(value):
                skipHealthCheck = value
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case skipHealthCheck = "SkipHealthCheck"
    }
}

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
