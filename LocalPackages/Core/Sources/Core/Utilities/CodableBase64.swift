//
// CodableBase64.swift
// Proton Pass - Created on 28/09/2022.
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

import Foundation

/// Protocol that helps serializing and deserialzing a `Codable` object
public protocol CodableBase64: Codable {
    /// Serialize a `Codable` object into a JSON string and then base 64 encode that JSON string
    func serializeBase64() throws -> String

    /// Deserialize a `Codable` object from a base 64 string of a JSON string
    static func deserializeBase64(_ base64String: String) throws -> Self
}

public extension CodableBase64 {
    func serializeBase64() throws -> String {
        let data = try JSONEncoder().encode(self)
        return data.base64EncodedString()
    }

    static func deserializeBase64(_ base64String: String) throws -> Self {
        guard let data = Data(base64Encoded: base64String) else {
            throw PPCoreError.failedToConvertBase64StringToData(base64String)
        }
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
