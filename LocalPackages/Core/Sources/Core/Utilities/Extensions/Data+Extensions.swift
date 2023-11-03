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
}

// MARK: Computed Extensions

public extension Data {
    var utf8DataToString: String? {
        String(data: self, encoding: .utf8)
    }

    var mimeType: String {
        var copy: UInt8 = 0
        copyBytes(to: &copy, count: 1)
        return Data.mimeTypeSignatures[copy] ?? "application/octet-stream"
    }
}

// MARK: Utils

private extension Data {
    static let mimeTypeSignatures: [UInt8: String] = [
        0xFF: "image/jpeg",
        0x89: "image/png",
        0x47: "image/gif",
        0x49: "image/tiff",
        0x4D: "image/tiff",
        0x25: "application/pdf",
        0xD0: "application/vnd",
        0x46: "text/plain"
    ]
}
