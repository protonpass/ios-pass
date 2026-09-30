//
// CustomItemIconTests.swift
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

import Entities
import Foundation
import Testing

// Test vectors mirror the web client (`item-icon.spec.ts`)
private let pngBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
private let svgSource = #"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><rect width="1" height="1"/></svg>"#
private let svgBase64 = Data(svgSource.utf8).base64EncodedString()
private let htmlBase64 = Data("<script>alert(1)</script>".utf8).base64EncodedString()

private let pngIcon = "data:image/png;base64,\(pngBase64)"
private let svgIcon = "data:image/svg+xml;base64,\(svgBase64)"
private let jpegIcon = "data:image/jpeg;base64,\(pngBase64)"
private let webpIcon = "data:image/webp;base64,\(pngBase64)"
private let pngPrefix = "data:image/png;base64,"

@Suite(.tags(.entity))
struct CustomItemIconTests {
    @Test("Accept valid data URIs", arguments: [
        pngIcon,
        svgIcon,
        jpegIcon,
        webpIcon,
        "data:image/png;base64,QUJD", // no padding
        "data:image/png;base64,QUI=", // single padding
        "data:image/png;base64,QQ==" // double padding
    ])
    func acceptValid(icon: String) {
        #expect(CustomItemIcon.isValid(icon))
        #expect(CustomItemIcon.validated(icon) == icon)
    }

    @Test("Accept data URI of exactly max length")
    func acceptMaxLength() {
        let icon = pngPrefix + String(repeating: "A", count: CustomItemIcon.maxLength - pngPrefix.count)
        #expect(icon.count == CustomItemIcon.maxLength)
        #expect(CustomItemIcon.isValid(icon))
    }

    @Test("Reject data URI longer than max length")
    func rejectTooLong() {
        let icon = pngPrefix + String(repeating: "A", count: CustomItemIcon.maxLength - pngPrefix.count + 1)
        #expect(!CustomItemIcon.isValid(icon))
        #expect(CustomItemIcon.validated(icon) == nil)
    }

    @Test("Reject invalid values", arguments: [
        "https://tracker.example.com/pixel.png",
        "http://tracker.example.com/pixel.png",
        "//tracker.example.com/pixel.png",
        "javascript:alert(1)",
        "javascript:data:image/png;base64,QUJD",
        "blob:https://example.com/0000-0000",
        "data:text/html;base64,\(htmlBase64)",
        "data:image/gif;base64,QUJD",
        "data:IMAGE/PNG;base64,QUJD", // uppercase mime type
        #"data:image/svg+xml,<svg onload="alert(1)"></svg>"#, // non-base64
        "data:image/svg+xml;utf8,<svg></svg>",
        "data:image/png;charset=utf-8;base64,QUJD", // extra mime parameters
        "data:image/png;base64,QUJD<script>",
        "data:image/png;base64,QUJD QUJD", // whitespace in payload
        "data:image/png;base64,QUJD\nQUJD", // newline in payload
        "\(pngIcon)\n", // trailing newline
        "data:image/png;base64,QU-_QUJD", // url-safe base64 characters
        "data:image/png;base64,QQ===", // too much padding
        "data:image/png;base64,QQ==QUJD", // padding in the middle
        "data:image/png;base64,=", // padding only
        "data:image/png;base64,", // empty payload
        " \(pngIcon)", // leading whitespace
        "data:image/png\u{037E}base64,QUJD", // Greek question mark, canonically equivalent to `;`
        "data:image/png;base64,QUJD\u{301}", // combining character
        ""
    ])
    func rejectInvalid(icon: String) {
        #expect(!CustomItemIcon.isValid(icon))
        #expect(CustomItemIcon.validated(icon) == nil)
        #expect(CustomItemIcon.decode(icon) == nil)
    }

    @Test("Reject nil")
    func rejectNil() {
        #expect(!CustomItemIcon.isValid(nil))
        #expect(CustomItemIcon.validated(nil) == nil)
        #expect(CustomItemIcon.mimeType(of: nil) == nil)
    }

    @Test("Get MIME type")
    func mimeType() {
        #expect(CustomItemIcon.mimeType(of: pngIcon) == .png)
        #expect(CustomItemIcon.mimeType(of: jpegIcon) == .jpeg)
        #expect(CustomItemIcon.mimeType(of: webpIcon) == .webp)
        #expect(CustomItemIcon.mimeType(of: svgIcon) == .svg)
        #expect(CustomItemIcon.mimeType(of: "https://example.com/icon.png") == nil)
        #expect(CustomItemIcon.MimeType.svg.isRaster == false)
        #expect(CustomItemIcon.MimeType.png.isRaster)
    }

    @Test("Decode payload")
    func decode() throws {
        let png = try #require(CustomItemIcon.decode(pngIcon))
        #expect(png.mimeType == .png)
        #expect(png.data == Data(base64Encoded: pngBase64))

        let svg = try #require(CustomItemIcon.decode(svgIcon))
        #expect(svg.mimeType == .svg)
        #expect(String(data: svg.data, encoding: .utf8)?.hasPrefix("<svg") == true)
    }

    @Test("Decode unpadded payload")
    func decodeUnpadded() throws {
        #expect(try #require(CustomItemIcon.decode("data:image/png;base64,QUI")).data == Data("AB".utf8))
        #expect(try #require(CustomItemIcon.decode("data:image/png;base64,QQ")).data == Data("A".utf8))
        // Valid per the grammar but not decodable
        #expect(CustomItemIcon.decode("data:image/png;base64,A") == nil)
    }

    @Test("Build data URI")
    func dataUri() throws {
        let data = try #require(Data(base64Encoded: pngBase64))
        let icon = CustomItemIcon.dataUri(mimeType: .png, data: data)
        #expect(icon == pngIcon)
        #expect(CustomItemIcon.dataUriLength(mimeType: .png, byteCount: data.count) == icon.count)
    }

    @Test("Compute data URI length", arguments: [0, 1, 2, 3, 4, 5, 6, 1_000, 24_576])
    func dataUriLength(byteCount: Int) {
        let data = Data(repeating: 0, count: byteCount)
        for mimeType in CustomItemIcon.MimeType.allCases {
            let expected = CustomItemIcon.dataUri(mimeType: mimeType, data: data).count
            #expect(CustomItemIcon.dataUriLength(mimeType: mimeType, byteCount: byteCount) == expected)
        }
    }
}
