//
// UpdateVaultEndpoint.swift
// Proton Pass - Created on 24/03/2023.
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

import ProtonCoreNetworking
import ProtonCoreServices

public struct UpdateVaultResponse: Decodable {
    let code: Int
    let share: Share
}

public struct UpdateVaultEndpoint: Endpoint {
    public typealias Body = UpdateVaultRequest
    public typealias Response = UpdateVaultResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: UpdateVaultRequest?

    public init(shareId: String, request: UpdateVaultRequest) {
        debugDescription = "Edit vault"
        path = "/pass/v1/vault/\(shareId)"
        method = .put
        body = request
    }
}
