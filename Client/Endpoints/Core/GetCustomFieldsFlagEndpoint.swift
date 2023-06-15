//
// GetCustomFieldsFlagEndpoint.swift
// Proton Pass - Created on 31/05/2023.
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

public struct GetCustomFieldsFlagResponse: Decodable {
    let code: Int
    let feature: FeatureFlagResponse
}

public struct FeatureFlagResponse: Decodable {
    public let value: Bool
}

public enum FeatureFlagType {
    case creditCardV1, customFields

    var path: String {
        switch self {
        case .creditCardV1:
            return "PassCreditCardsV1"
        case .customFields:
            return "PassCustomFields"
        }
    }
}

public struct GetCustomFieldsFlagEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetCustomFieldsFlagResponse

    public var debugDescription: String
    public var path: String

    public init(flagType: FeatureFlagType) {
        self.debugDescription = "Get feature flag \(flagType.path)"
        self.path = "/core/v4/features/\(flagType.path)"
    }
}
