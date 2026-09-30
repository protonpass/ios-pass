//
// CustomItemIcon.swift
// Proton Pass - Created on 29/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
//

import Foundation

/// Custom item icons are stored inline in the item's protobuf `Metadata.icon` field
/// as a base64 image data URI. Rules mirror the web client (`item-icon.ts`).
///
/// SECURITY: items can be shared, so the `icon` field is untrusted input. A malicious sharer
/// could set it to a remote URL (to track who opens the vault) or to any other scheme.
/// Only strictly validated base64 image data URIs may ever be decoded or rendered.
public enum CustomItemIcon {
    /// Raster output size in pixels (square)
    public static let rasterSize = 64
    /// Maximum source file size in bytes of the web client, which also accepts SVG.
    /// iOS only accepts raster sources, see `CustomItemIconProcessor.maxRasterInputSize`
    public static let maxInputSize = 512 * 1_024
    /// Maximum data URI length stored in the item
    public static let maxLength = 32 * 1_024

    public enum MimeType: String, CaseIterable, Sendable {
        case png = "image/png"
        case jpeg = "image/jpeg"
        case webp = "image/webp"
        case svg = "image/svg+xml"

        public var isRaster: Bool {
            self != .svg
        }

        var dataUriPrefix: String {
            "data:\(rawValue);base64,"
        }
    }

    /// Strict check: at most `maxLength` long and matching
    /// `^data:image\/(png|jpeg|webp|svg\+xml);base64,[A-Za-z0-9+/]+={0,2}$`
    public static func isValid(_ icon: String?) -> Bool {
        parse(icon) != nil
    }

    /// Returns the icon if valid, otherwise `nil`
    public static func validated(_ icon: String?) -> String? {
        isValid(icon) ? icon : nil
    }

    /// Returns the MIME type of a valid icon without decoding its payload, otherwise `nil`
    public static func mimeType(of icon: String?) -> MimeType? {
        parse(icon)?.mimeType
    }

    /// Returns the MIME type and the decoded bytes of a valid icon, otherwise `nil`
    public static func decode(_ icon: String?) -> (mimeType: MimeType, data: Data)? {
        guard let parsed = parse(icon) else { return nil }
        // The accepted grammar does not require padding but `Data(base64Encoded:)` does
        let padding = switch parsed.payload.utf8.count % 4 {
        case 2: "=="
        case 3: "="
        default: ""
        }
        guard let data = Data(base64Encoded: parsed.payload + padding), !data.isEmpty else { return nil }
        return (parsed.mimeType, data)
    }

    public static func dataUri(mimeType: MimeType, data: Data) -> String {
        mimeType.dataUriPrefix + data.base64EncodedString()
    }

    /// Length of a base64 data URI for `byteCount` bytes of `mimeType`
    public static func dataUriLength(mimeType: MimeType, byteCount: Int) -> Int {
        mimeType.dataUriPrefix.utf8.count + (byteCount + 2) / 3 * 4
    }
}

private extension CustomItemIcon {
    static let base64Bytes = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".utf8)
    static let paddingByte = UInt8(ascii: "=")

    /// Byte-level equivalent of the web regex. `String` comparison is avoided on purpose
    /// because it applies Unicode canonical equivalence (e.g. U+037E matches `;`).
    static func parse(_ icon: String?) -> (mimeType: MimeType, payload: String)? {
        guard let icon else { return nil }
        let bytes = icon.utf8
        guard bytes.count <= maxLength,
              let mimeType = MimeType.allCases.first(where: { bytes.starts(with: $0.dataUriPrefix.utf8) }) else {
            return nil
        }

        let payload = bytes.dropFirst(mimeType.dataUriPrefix.utf8.count)
        let paddingCount = payload.reversed().prefix(while: { $0 == paddingByte }).count
        let body = payload.dropLast(paddingCount)

        guard paddingCount <= 2,
              !body.isEmpty,
              body.allSatisfy({ base64Bytes.contains($0) }) else {
            return nil
        }

        return (mimeType, String(decoding: payload, as: UTF8.self))
    }
}
