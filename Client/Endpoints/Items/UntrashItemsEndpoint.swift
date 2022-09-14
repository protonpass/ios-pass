//
// UntrashItemsEndpoint.swift
// Proton Pass - Created on 14/09/2022.
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

import ProtonCore_Networking
import ProtonCore_Services

public struct UntrashItemsEndpoint: Endpoint {
    public typealias Body = ModifyItemRequest
    public typealias Response = ModifyItemResponse

    public var path: String
    public var method: HTTPMethod
    public var authCredential: AuthCredential?
    public var body: ModifyItemRequest?

    public init(credential: AuthCredential,
                shareId: String,
                request: ModifyItemRequest) {
        self.path = "/pass/v1/share/\(shareId)/item/untrash"
        self.method = .post
        self.authCredential = credential
        self.body = request
    }
}
