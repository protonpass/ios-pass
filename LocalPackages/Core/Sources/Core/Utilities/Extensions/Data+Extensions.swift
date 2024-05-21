//
// Data+Extensions.swift
// Proton Pass - Created on 14/04/2023.
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

public extension Data {
    static func random(byteCount: Int = 32) throws -> Data {
        var data = Data(count: byteCount)
        _ = try data.withUnsafeMutableBytes { byte in
            guard let baseAddress = byte.baseAddress else {
                throw PPCoreError.failedToRandomizeData
            }
            return SecRandomCopyBytes(kSecRandomDefault, byteCount, baseAddress)
        }
        return data
    }

    /// Url secure base 64 encoding of data this follows the base 64 url standard
    /// https://base64.guru/standards/base64url
    /// - Returns: A string that is url safe
    func base64URLSafeEncodedString() -> String {
        let base64String = base64EncodedString()
        let urlSafeBase64String = base64String
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return urlSafeBase64String
    }
}
