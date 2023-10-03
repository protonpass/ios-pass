//
// FeatureFlag.swift
// Proton - Created on 29/09/2023.
// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton.
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

public struct FeatureFlag: Codable, Equatable, Hashable, Sendable {
    public let name: String
    public let enabled: Bool
    public let variant: FeatureFlagVariant?
}

// MARK: - Variant

public struct FeatureFlagVariant: Codable, Equatable, Hashable, Sendable {
    public let name: String
    public let enabled: Bool
    public let payload: FeatureFlagVariantPayload?
}

// MARK: - Payload

public struct FeatureFlagVariantPayload: Codable, Equatable, Hashable, Sendable {
    public let type: String
    public let value: FeatureFlagVariantPayloadValue
}

// As we don't know the exact type of the payload from unleash we should update the following as explained in
// https://stackoverflow.com/questions/52681385/swift-codable-multiple-types
// If new cases are implemented on the unleash backend we need to update the parsing cases
public enum FeatureFlagVariantPayloadValue: Codable, Equatable, Hashable, Sendable {
    case string(String)
    case nonDecodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        } else {
            self = .nonDecodable
        }
        throw DecodingError.typeMismatch(FeatureFlagVariantPayloadValue.self,
                                         DecodingError.Context(codingPath: decoder.codingPath,
                                                               debugDescription: "Wrong type for MyValue"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        default:
            return
        }
    }

    public var stringValue: String? {
        switch self {
        case let .string(value):
            value
        default:
            nil
        }
    }
}
