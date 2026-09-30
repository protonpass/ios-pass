//
// CustomItemIconProcessorTests.swift
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

import Core
import CoreGraphics
import Entities
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

private let svgSource = #"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><rect width="1" height="1"/></svg>"#

struct CustomItemIconProcessorTests {
    @Test("Accepted MIME types mirror the web client")
    func acceptedMimeTypes() {
        #expect(CustomItemIcon.MimeType.allCases.map(\.rawValue) ==
            ["image/png", "image/jpeg", "image/webp", "image/svg+xml"])
    }

    @Test("Reject unaccepted MIME type",
          arguments: ["", "image/gif", "image/bmp", "image/heic", "text/html", "application/octet-stream",
                      "image/svg", "IMAGE/PNG"])
    func rejectMimeType(mimeType: String) throws {
        let data = try makeImageData(width: 8, height: 8, type: .png)
        #expect(throws: CustomItemIconError.type) {
            try CustomItemIconProcessor.process(data: data, mimeType: mimeType)
        }
    }

    @Test("Reject input larger than max raster input size", arguments: [CustomItemIcon.MimeType.png, .jpeg, .webp])
    func rejectInputSize(mimeType: CustomItemIcon.MimeType) {
        let data = Data(repeating: 0, count: CustomItemIconProcessor.maxRasterInputSize + 1)
        #expect(throws: CustomItemIconError.size) {
            try CustomItemIconProcessor.process(data: data, mimeType: mimeType.rawValue)
        }
    }

    @Test("Check MIME type before size")
    func typeBeforeSize() {
        let data = Data(repeating: 0, count: CustomItemIconProcessor.maxRasterInputSize + 1)
        #expect(throws: CustomItemIconError.type) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/gif")
        }
    }

    @Test("Reject SVG because it cannot be verified",
          arguments: [Data(svgSource.utf8), Data(), Data(repeating: 0, count: CustomItemIcon.maxLength)])
    func rejectSvg(data: Data) {
        #expect(throws: CustomItemIconError.type) {
            try CustomItemIconProcessor.process(data: data, mimeType: CustomItemIcon.MimeType.svg.rawValue)
        }
    }

    @Test("Accept a photo larger than the web client's max input size")
    func acceptLargePhoto() throws {
        // Noise does not compress, like a real photo
        let data = try makeImageData(width: 2_000, height: 1_500, type: .jpeg) { context in
            guard let pixels = context.data else { return }
            var generator = SystemRandomNumberGenerator()
            for offset in stride(from: 0, to: context.bytesPerRow * context.height, by: 8) {
                pixels.storeBytes(of: generator.next(), toByteOffset: offset, as: UInt64.self)
            }
        }
        try #require(data.count > CustomItemIcon.maxInputSize)

        let icon = try CustomItemIconProcessor.process(data: data, mimeType: "image/jpeg")

        let output = try decodeImage(icon)
        #expect(output.width == CustomItemIcon.rasterSize)
        #expect(output.height == CustomItemIcon.rasterSize)
    }

    @Test("Accept a 48 MP photo")
    func accept48MegapixelPhoto() throws {
        // Resolution of the 48 MP iPhone cameras
        let data = try makeLargeJpeg(width: 8_064, height: 6_048)
        try #require(data.count <= CustomItemIconProcessor.maxRasterInputSize)

        let icon = try CustomItemIconProcessor.process(data: data, mimeType: "image/jpeg")

        let output = try decodeImage(icon)
        #expect(output.width == CustomItemIcon.rasterSize)
        #expect(output.height == CustomItemIcon.rasterSize)
    }

    @Test("Resolution limits per type")
    func maxMegapixels() {
        #expect(CustomItemIconProcessor.maxMegapixels(for: .jpeg) == 100)
        #expect(CustomItemIconProcessor.maxMegapixels(for: .png) == 40)
        #expect(CustomItemIconProcessor.maxMegapixels(for: .webp) == 40)
    }

    @Test("Reject source dimensions that would exhaust memory when decoded",
          arguments: [(8_193, 1), (1, 8_193)])
    func rejectLargeDimensions(width: Int, height: Int) throws {
        let data = try makeImageData(width: width, height: height, type: .png)
        #expect(throws: CustomItemIconError.dimensions(maxMegapixels: 40)) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        }
    }

    @Test("Reject a PNG with the resolution of a 48 MP photo")
    func rejectLargePng() throws {
        // Both sides are allowed but 8064 x 6048 is over the PNG pixel count limit
        let data = try makeBombPng(width: 8_064, height: 6_048)
        #expect(throws: CustomItemIconError.dimensions(maxMegapixels: 40)) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        }
    }

    @Test("Reject JPEG dimensions over the JPEG limits",
          arguments: [(12_001, 1), (1, 12_001), (12_000, 8_334)])
    func rejectLargeJpegDimensions(width: Int, height: Int) throws {
        let data = try makeLargeJpeg(width: width, height: height)
        #expect(throws: CustomItemIconError.dimensions(maxMegapixels: 100)) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/jpeg")
        }
    }

    @Test("Reject decompression bomb before decoding")
    func rejectDecompressionBomb() throws {
        // Both sides are allowed but 6400 x 6400 is over the pixel count limit
        let data = try makeBombPng(width: 6_400, height: 6_400)
        try #require(data.count <= CustomItemIcon.maxInputSize)
        #expect(throws: CustomItemIconError.dimensions(maxMegapixels: 40)) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        }
    }

    @Test("Reject bytes that do not match the declared type", arguments: mismatchedTypes)
    func rejectMismatchedType(type: UTType) throws {
        let data = try makeImageData(width: 16, height: 16, type: type)
        #expect(throws: CustomItemIconError.decode) {
            try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        }
    }

    @Test("Reject undecodable raster data", arguments: [CustomItemIcon.MimeType.png, .jpeg, .webp])
    func rejectUndecodableRaster(mimeType: CustomItemIcon.MimeType) {
        #expect(throws: CustomItemIconError.decode) {
            try CustomItemIconProcessor.process(data: Data("not an image".utf8), mimeType: mimeType.rawValue)
        }
    }

    @Test("Rasterize to a 64x64 PNG",
          arguments: [(UTType.png, 1, 1), (.png, 300, 100), (.png, 100, 300), (.jpeg, 1_000, 800), (.png, 64, 64)])
    func rasterize(type: UTType, width: Int, height: Int) throws {
        let data = try makeImageData(width: width, height: height, type: type)
        let mimeType = try #require(type.preferredMIMEType)

        let icon = try CustomItemIconProcessor.process(data: data, mimeType: mimeType)

        #expect(icon.hasPrefix("data:image/png;base64,"))
        #expect(icon.count <= CustomItemIcon.maxLength)
        #expect(CustomItemIcon.isValid(icon))
        let output = try decodeImage(icon)
        #expect(output.width == CustomItemIcon.rasterSize)
        #expect(output.height == CustomItemIcon.rasterSize)
    }

    @Test("Stay under max length for images that do not compress")
    func noisyImage() throws {
        var generator = SystemRandomNumberGenerator()
        let data = try makeImageData(width: 512, height: 512, type: .png) { context in
            for x in 0..<128 {
                for y in 0..<128 {
                    context.setFillColor(red: .random(in: 0...1, using: &generator),
                                         green: .random(in: 0...1, using: &generator),
                                         blue: .random(in: 0...1, using: &generator),
                                         alpha: .random(in: 0...1, using: &generator))
                    context.fill(CGRect(x: x * 4, y: y * 4, width: 4, height: 4))
                }
            }
        }
        try #require(data.count <= CustomItemIcon.maxInputSize)

        let icon = try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        #expect(icon.count <= CustomItemIcon.maxLength)
    }

    @Test("Center-crop landscape and portrait images", arguments: [(300, 100), (100, 300)])
    func centerCrop(width: Int, height: Int) throws {
        // Red square in the middle, blue on both long-side edges
        let data = try makeImageData(width: width, height: height, type: .png) { context in
            context.setFillColor(red: 0, green: 0, blue: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            let side = min(width, height)
            context.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
            context.fill(CGRect(x: (width - side) / 2, y: (height - side) / 2, width: side, height: side))
        }

        let icon = try CustomItemIconProcessor.process(data: data, mimeType: "image/png")
        let output = try decodeImage(icon)

        let last = CustomItemIcon.rasterSize - 1
        for (x, y) in [(0, 0), (last, 0), (0, last), (last, last), (last / 2, last / 2)] {
            let pixel = try rgba(of: output, x: x, y: y)
            #expect(pixel.red > 200 && pixel.blue < 50, "Pixel at (\(x), \(y)) should be red: \(pixel)")
        }
    }

    @Test("Sniff MIME type from bytes")
    func sniffMimeType() throws {
        #expect(try CustomItemIconProcessor.sniffMimeType(of: makeImageData(width: 4, height: 4, type: .png)) ==
            "image/png")
        #expect(try CustomItemIconProcessor.sniffMimeType(of: makeImageData(width: 4, height: 4, type: .jpeg)) ==
            "image/jpeg")
        #expect(CustomItemIconProcessor.sniffMimeType(of: Data("not an image".utf8)) == nil)
    }

    @Test("Render valid raster icon")
    func renderRaster() throws {
        let data = try makeImageData(width: 300, height: 100, type: .png)
        let icon = try CustomItemIconProcessor.process(data: data, mimeType: "image/png")

        let image = try #require(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180))
        #expect(image.width == CustomItemIcon.rasterSize)
        #expect(image.height == CustomItemIcon.rasterSize)
    }

    @Test("Downsample oversized icon when rendering")
    func renderDownsampled() throws {
        let data = try makeImageData(width: 200, height: 200, type: .png)
        let icon = CustomItemIcon.dataUri(mimeType: .png, data: data)
        try #require(CustomItemIcon.isValid(icon))

        let image = try #require(CustomItemIconRenderer.image(from: icon, maxPixelSize: 50))
        #expect(max(image.width, image.height) <= 50)
    }

    @Test("Do not render SVG, invalid or undecodable icons", arguments: [
        nil,
        "",
        "https://tracker.example.com/pixel.png",
        "data:image/svg+xml;base64,\(Data(svgSource.utf8).base64EncodedString())",
        "data:image/png;base64,QUJD",
        "data:image/png;base64,QUJD<script>"
    ])
    func doNotRender(icon: String?) {
        #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) == nil)
    }

    @Test("Do not render bytes that do not match the declared type", arguments: mismatchedTypes)
    func doNotRenderMismatchedType(type: UTType) throws {
        let data = try makeImageData(width: 16, height: 16, type: type)
        for mimeType in [CustomItemIcon.MimeType.png, .jpeg, .webp] where UTType(mimeType: mimeType.rawValue) != type {
            let icon = CustomItemIcon.dataUri(mimeType: mimeType, data: data)
            try #require(CustomItemIcon.isValid(icon))
            #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) == nil,
                    "\(type.identifier) declared as \(mimeType.rawValue)")
        }
    }

    @Test("Do not render multi-frame images")
    func doNotRenderAnimated() throws {
        let data = try makeImageData(width: 8, height: 8, type: .png, frameCount: 2)
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        try #require(CGImageSourceGetCount(source) == 2)

        let icon = CustomItemIcon.dataUri(mimeType: .png, data: data)
        #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) == nil)
    }

    @Test("Do not render oversized dimensions", arguments: [(513, 1), (1, 513)])
    func doNotRenderLargeDimensions(width: Int, height: Int) throws {
        let data = try makeImageData(width: width, height: height, type: .png)
        let icon = CustomItemIcon.dataUri(mimeType: .png, data: data)
        try #require(CustomItemIcon.isValid(icon))
        #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) == nil)
    }

    @Test("Do not render decompression bomb")
    func doNotRenderDecompressionBomb() throws {
        let icon = try CustomItemIcon.dataUri(mimeType: .png, data: makeBombPng(width: 14_000, height: 14_000))
        try #require(CustomItemIcon.isValid(icon))
        #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) == nil)
    }

    @Test("Render largest accepted dimensions")
    func renderLargestDimensions() throws {
        let data = try makeImageData(width: 512, height: 512, type: .png)
        let icon = CustomItemIcon.dataUri(mimeType: .png, data: data)
        try #require(CustomItemIcon.isValid(icon))
        #expect(CustomItemIconRenderer.image(from: icon, maxPixelSize: 180) != nil)
    }

    @Test("Cache rendered icons")
    @MainActor
    func cache() throws {
        let icon = try CustomItemIconProcessor.process(data: makeImageData(width: 8, height: 8, type: .png),
                                                       mimeType: "image/png")
        let image = try #require(CustomItemIconImageCache.image(for: icon))
        #expect(CustomItemIconImageCache.image(for: icon) === image)
        #expect(CustomItemIconImageCache.image(for: nil) == nil)
        #expect(CustomItemIconImageCache.image(for: "data:image/png;base64,QUJD") == nil)
    }
}

/// Formats ImageIO decodes although they are not accepted, plus an accepted one to prove the exact type is checked
private let mismatchedTypes: [UTType] = [.gif, .tiff, .bmp, .ico, .pdf, .jpeg]

// MARK: - Helpers

private struct RGBA: CustomStringConvertible {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    var description: String {
        "rgba(\(red), \(green), \(blue), \(alpha))"
    }
}

private func makeImageData(width: Int,
                           height: Int,
                           type: UTType,
                           frameCount: Int = 1,
                           draw: ((CGContext) -> Void)? = nil) throws -> Data {
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let context = try #require(CGContext(data: nil,
                                         width: width,
                                         height: height,
                                         bitsPerComponent: 8,
                                         bytesPerRow: 0,
                                         space: colorSpace,
                                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    if let draw {
        draw(context)
    } else {
        context.setFillColor(red: 0, green: 1, blue: 0, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    }
    let image = try #require(context.makeImage())

    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data as CFMutableData,
                                                                    type.identifier as CFString,
                                                                    frameCount,
                                                                    nil))
    for _ in 0..<frameCount {
        CGImageDestinationAddImage(destination, image, nil)
    }
    try #require(CGImageDestinationFinalize(destination))
    return data as Data
}

/// 1-bit grayscale PNG of zeros: a few KB to store, `width * height` pixels once decoded
private func makeBombPng(width: Int, height: Int) throws -> Data {
    // Each row is a filter type byte followed by the packed pixels
    let raw = Data(count: (1 + (width + 7) / 8) * height)
    // `.zlib` is raw DEFLATE: wrap it in a zlib stream. The Adler-32 of n zero bytes is (n % 65521) << 16 | 1
    let zlib = try Data([0x78, 0x9C]) + (raw as NSData).compressed(using: .zlib) +
        bigEndian(UInt32(raw.count % 65_521) << 16 | 1)

    let header = bigEndian(UInt32(width)) + bigEndian(UInt32(height)) + Data([1, 0, 0, 0, 0])
    return Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) +
        pngChunk("IHDR", header) + pngChunk("IDAT", zlib) + pngChunk("IEND", Data())
}

/// Uniform gray JPEG encoded from rows generated on demand, so that 100 MP fixtures do not need a 300 MB bitmap
private func makeLargeJpeg(width: Int, height: Int) throws -> Data {
    var callbacks = CGDataProviderSequentialCallbacks(version: 0,
                                                      getBytes: { _, buffer, count in
                                                          memset(buffer, 0x80, count)
                                                          return count
                                                      },
                                                      skipForward: { _, count in count },
                                                      rewind: { _ in },
                                                      releaseInfo: nil)
    let provider = try #require(CGDataProvider(sequentialInfo: nil, callbacks: &callbacks))
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    let image = try #require(CGImage(width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bitsPerPixel: 24,
                                     bytesPerRow: width * 3,
                                     space: colorSpace,
                                     bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                                     provider: provider,
                                     decode: nil,
                                     shouldInterpolate: false,
                                     intent: .defaultIntent))
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(data as CFMutableData,
                                                                    UTType.jpeg.identifier as CFString,
                                                                    1,
                                                                    nil))
    CGImageDestinationAddImage(destination, image, nil)
    try #require(CGImageDestinationFinalize(destination))
    return data as Data
}

private func pngChunk(_ type: String, _ body: Data) -> Data {
    let typeAndBody = Data(type.utf8) + body
    return bigEndian(UInt32(body.count)) + typeAndBody + bigEndian(crc32(typeAndBody))
}

private func bigEndian(_ value: UInt32) -> Data {
    withUnsafeBytes(of: value.bigEndian) { Data($0) }
}

private func crc32(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
        crc ^= UInt32(byte)
        for _ in 0..<8 {
            crc = crc & 1 == 1 ? (crc >> 1) ^ 0xEDB8_8320 : crc >> 1
        }
    }
    return ~crc
}

private func decodeImage(_ icon: String) throws -> CGImage {
    let decoded = try #require(CustomItemIcon.decode(icon))
    let source = try #require(CGImageSourceCreateWithData(decoded.data as CFData, nil))
    return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
}

/// Reads a pixel by redrawing the image into a known RGBA buffer (top-left origin)
private func rgba(of image: CGImage, x: Int, y: Int) throws -> RGBA {
    let width = image.width
    let height = image.height
    var buffer = [UInt8](repeating: 0, count: width * height * 4)
    let colorSpace = try #require(CGColorSpace(name: CGColorSpace.sRGB))
    try buffer.withUnsafeMutableBytes { pointer in
        let context = try #require(CGContext(data: pointer.baseAddress,
                                             width: width,
                                             height: height,
                                             bitsPerComponent: 8,
                                             bytesPerRow: width * 4,
                                             space: colorSpace,
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    let offset = (y * width + x) * 4
    return RGBA(red: buffer[offset],
                green: buffer[offset + 1],
                blue: buffer[offset + 2],
                alpha: buffer[offset + 3])
}
