//
// GetSubscriptionEndpoint.swift
// Proton Pass - Created on 05/04/2023.
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

public struct GetSubscriptionResponse: Decodable {
    public let code: Int
    public let subscription: SubcriptionLite
}

public struct GetSubscriptionEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetSubscriptionResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod

    public init() {
        self.debugDescription = "Get subscription"
        self.path = "/payments/v4/subscription"
        self.method = .get
    }
}

public struct SubcriptionLite: Decodable {
    let plans: [PlanLite]
}

public struct PlanLite: Codable {
    public let name: String
    public let title: String
    public let type: Int

    public var isPrimary: Bool { type == 1 }
}
