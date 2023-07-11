//
// InviteUserToShareEndpoint.swift
// Proton Pass - Created on 11/07/2023.
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

import ProtonCore_Networking
import ProtonCore_Services

public struct InviteUserToShareEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = CodeOnlyResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: InviteUserToShareRequest?

    public init(for shareId: String, with request: InviteUserToShareRequest) {
        debugDescription = "Invite a user to share."
        path = "/pass/v1/share/\(shareId)/invite"
        method = .post
        body = request
    }
}

public struct InviteUserToShareRequest {
    public let keys: [ItemKey]
    public let email: String
    public let targetType: String // 1 = Vault, 2 = Item
    public let itemId: String? // only for item sharing
    public let expirationDate: Int?

    public init(keys: [ItemKey],
                email: String,
                targetType: String,
                itemId: String? = nil,
                expirationDate: Int? = nil) {
        self.keys = keys
        self.email = email
        self.targetType = targetType
        self.itemId = itemId
        self.expirationDate = expirationDate
    }
}

extension InviteUserToShareRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case keys = "Keys"
        case email = "Email"
        case targetType = "TargetType"
        case itemId = "ItemID"
        case expirationDate = "ExpirationTime"
    }
}
