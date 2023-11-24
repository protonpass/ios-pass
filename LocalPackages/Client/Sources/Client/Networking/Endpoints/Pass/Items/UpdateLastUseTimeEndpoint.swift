//
// UpdateLastUseTimeEndpoint.swift
// Proton Pass - Created on 16/12/2022.
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

import Entities
import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

public struct UpdateLastUseTimeResponse: Decodable {
    public let code: Int
    public let revision: ItemRevision
}

public struct UpdateLastUseTimeEndpoint: Endpoint {
    public typealias Body = UpdateLastUseTimeRequest
    public typealias Response = UpdateLastUseTimeResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: UpdateLastUseTimeRequest?
    public var nonDefaultTimeout: TimeInterval?

    public init(shareId: String, itemId: String, lastUseTime: TimeInterval) {
        debugDescription = "Update item"
        path = "/pass/v1/share/\(shareId)/item/\(itemId)/lastuse"
        method = .put
        body = .init(lastUseTime: Int(lastUseTime))
        // This endpoint is used in the AutoFill extension only
        // We need to set a small timeout here for this specific request
        // Because the autofill extension implicitly expects completion task to be quick
        // long-running task will put the extension into a limbo state in which
        // users can not interact with the extension anymore (select to autofill, cancel autofill...)
        nonDefaultTimeout = 1
    }
}
