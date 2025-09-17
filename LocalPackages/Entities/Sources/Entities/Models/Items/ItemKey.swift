//
// ItemKey.swift
// Proton Pass - Created on 11/04/2023.
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

import Foundation

public typealias InviteKey = ItemKey

public struct ItemKey: Codable, Equatable, Hashable, Sendable {
    /// Encrypted key encoded in base64
    public let key: String
    public let keyRotation: Int64

    public init(key: String, keyRotation: Int64) {
        self.key = key
        self.keyRotation = keyRotation
    }

    enum CodingKeys: String, CodingKey {
        case key = "Key"
        case keyRotation = "KeyRotation"
    }

    // custom decoder
    public init(from decoder: any Decoder) throws {
        // keys that work with `JSONDecoder.KeyDecodingStrategy.decapitaliseFirstLetter`
        enum DecodingKeys: String, CodingKey {
            case key
            case keyRotation
        }
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        keyRotation = try container.decode(Int64.self, forKey: .keyRotation)
    }
}
