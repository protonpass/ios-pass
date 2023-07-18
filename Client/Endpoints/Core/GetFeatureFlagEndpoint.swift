//
// GetFeatureFlagEndpoint.swift
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

public struct GetFeatureFlagEndpointResponse: Decodable {
   public let code: Int
    public let toggles: [FeatureFlagResponse]
}

public struct FeatureFlagResponse: Codable {
    public let name: String
    public let enabled: Bool
    public let variant: Variant?
}

// MARK: - Variant

public struct Variant: Codable {
    public let name: String
    public let enabled: Bool
    public let payload: Payload?
}

// MARK: - Payload

public struct Payload: Codable {
    public let type, value: String
}

public enum FeatureFlagType: String, CaseIterable {
    case passSharingV1 = "PassSharingV1"
}

public struct GetFeatureFlagEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetFeatureFlagEndpointResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod

    public init() {
        debugDescription = "Get all feature flags from unleash"
        path = "/feature/v2/frontend"
        method = .get
    }
}
