//
// CustomItemIconProcessor.swift
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

import CoreGraphics
import Entities
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum CustomItemIconError: Error, Equatable, Sendable {
    /// Not one of `CustomItemIcon.MimeType`
    case type
    /// Input or output exceeds the size limits
    case size
    /// Source resolution exceeds `CustomItemIconProcessor.maxMegapixels(for:)` of its type
    case dimensions(maxMegapixels: Int)
    /// The image could not be decoded or encoded
    case decode
}

public enum CustomItemIconProcessor {
    /// Maximum source file size in bytes. Higher than the web client's `CustomItemIcon.maxInputSize`
    /// because photos are a few MB and the output is always re-rasterized: memory is bounded by
    /// the source dimensions instead, which are checked before decoding
    public static let maxRasterInputSize = 20 * 1_024 * 1_024

    /// Maximum source resolution in megapixels for a raster type, checked before decoding
    public static func maxMegapixels(for type: CustomItemIcon.MimeType) -> Int {
        SourceLimits(type).maxPixelCount / 1_000_000
    }

    /// Converts raster image bytes to a `CustomItemIcon` data URI:
    /// center-cropped and scaled to `CustomItemIcon.rasterSize`, exported as PNG.
    /// SVG is rejected because unlike the web client we cannot render it to prove it is an image.
    /// - Throws: `CustomItemIconError` on unaccepted type, oversize input/output, too high resolution
    ///   or decoding failure.
    public static func process(data: Data, mimeType: String) throws -> String {
        guard let type = CustomItemIcon.MimeType(rawValue: mimeType), type.isRaster else {
            throw CustomItemIconError.type
        }

        guard data.count <= maxRasterInputSize else {
            throw CustomItemIconError.size
        }

        let icon = try CustomItemIcon.dataUri(mimeType: .png, data: rasterize(data, type: type))

        guard icon.utf8.count <= CustomItemIcon.maxLength else {
            throw CustomItemIconError.size
        }

        guard CustomItemIcon.isValid(icon) else {
            throw CustomItemIconError.decode
        }

        return icon
    }

    /// MIME type sniffed from the image bytes rather than trusting the declared type
    public static func sniffMimeType(of data: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let identifier = CGImageSourceGetType(source) as String?,
              let type = UTType(identifier) else {
            return nil
        }
        return type.preferredMIMEType
    }
}

/// Upper bounds of the source image, read from its header before decoding.
/// The thumbnail API only bounds the output: PNG and WebP are still fully decoded first,
/// so a small file with huge dimensions (decompression bomb) could allocate gigabytes.
/// JPEG is downscaled while decoding (DCT scaling): 48 MP and 100 MP JPEGs, baseline or progressive,
/// raise peak memory by about 10-20 MB instead of the 190-380 MB of a full decode, so 48 MP photos are allowed
private struct SourceLimits {
    let maxPixelSize: Int
    let maxPixelCount: Int

    init(_ type: CustomItemIcon.MimeType) {
        switch type {
        case .jpeg:
            maxPixelSize = 12_000
            maxPixelCount = 100_000_000

        case .png, .svg, .webp:
            maxPixelSize = 8_192
            maxPixelCount = 40_000_000
        }
    }
}

private extension CustomItemIconProcessor {
    /// Upper bound of the downsampled image for extreme aspect ratios
    static let maxDecodedPixelSize = 4_096

    static func rasterize(_ data: Data, type: CustomItemIcon.MimeType) throws -> Data {
        let size = CustomItemIcon.rasterSize

        guard let source = makeImageSource(data, type: type),
              CGImageSourceGetCount(source) > 0,
              let sourceSize = pixelSize(of: source) else {
            throw CustomItemIconError.decode
        }

        let (sourceWidth, sourceHeight) = sourceSize
        let limits = SourceLimits(type)
        guard sourceWidth <= limits.maxPixelSize,
              sourceHeight <= limits.maxPixelSize,
              sourceWidth * sourceHeight <= limits.maxPixelCount else {
            throw CustomItemIconError.dimensions(maxMegapixels: maxMegapixels(for: type))
        }

        // Downsample while decoding, keeping enough pixels on the short side to crop a sharp square
        let aspectRatio = Double(max(sourceWidth, sourceHeight)) / Double(min(sourceWidth, sourceHeight))
        let maxPixelSize = min(maxDecodedPixelSize, Int((Double(size * 2) * aspectRatio).rounded(.up)))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary),
              image.width > 0, image.height > 0 else {
            throw CustomItemIconError.decode
        }

        let side = min(image.width, image.height)
        let cropRect = CGRect(x: (image.width - side) / 2,
                              y: (image.height - side) / 2,
                              width: side,
                              height: side)

        guard let cropped = image.cropping(to: cropRect),
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                      width: size,
                                      height: size,
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CustomItemIconError.decode
        }

        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: size, height: size))

        guard let output = context.makeImage() else {
            throw CustomItemIconError.decode
        }

        return try pngData(of: output)
    }

    static func pngData(of image: CGImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData,
                                                                 UTType.png.identifier as CFString,
                                                                 1,
                                                                 nil) else {
            throw CustomItemIconError.decode
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw CustomItemIconError.decode
        }
        return data as Data
    }
}

public enum CustomItemIconRenderer {
    /// Stored icons are `CustomItemIcon.rasterSize` pixels wide, anything much larger is not
    /// produced by a Pass client and could be a decompression bomb
    static let maxSourcePixelSize = 512

    /// Decodes a raster `CustomItemIcon` for display, downsampled to `maxPixelSize`.
    /// Returns `nil` for invalid icons, SVGs (not supported), bytes that do not match the declared type,
    /// multi-frame or oversized images and undecodable data.
    public static func image(from icon: String?, maxPixelSize: Int) -> CGImage? {
        // Icons come from shared items: only a single-frame image of the declared type and
        // of reasonable dimensions (read from its header) is ever handed to the decoder
        guard let decoded = CustomItemIcon.decode(icon),
              decoded.mimeType.isRaster,
              let source = makeImageSource(decoded.data, type: decoded.mimeType),
              CGImageSourceGetCount(source) == 1,
              let size = pixelSize(of: source),
              (1...maxSourcePixelSize).contains(size.width),
              (1...maxSourcePixelSize).contains(size.height) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}

/// Decoded custom icons shared by all views so that they are not decoded on every render
@MainActor
public enum CustomItemIconImageCache {
    /// Largest thumbnail is 60pt, keep enough pixels for 3x screens
    public static let maxPixelSize = 180

    private static let cache = NSCache<NSString, CGImage>()

    public static func image(for icon: String?) -> CGImage? {
        guard let icon else { return nil }
        let key = icon as NSString
        if let image = cache.object(forKey: key) {
            return image
        }
        guard let image = CustomItemIconRenderer.image(from: icon, maxPixelSize: maxPixelSize) else {
            return nil
        }
        cache.setObject(image, forKey: key)
        return image
    }
}

// MARK: - Image source

private extension CustomItemIcon.MimeType {
    var typeIdentifier: String {
        switch self {
        case .png:
            UTType.png.identifier

        case .jpeg:
            UTType.jpeg.identifier

        case .webp:
            UTType.webP.identifier

        case .svg:
            UTType.svg.identifier
        }
    }
}

/// ImageIO sniffs the real format from the bytes regardless of the declared type,
/// so only accept a source whose detected type is the declared one
private func makeImageSource(_ data: Data, type: CustomItemIcon.MimeType) -> CGImageSource? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          CGImageSourceGetType(source) as String? == type.typeIdentifier else {
        return nil
    }
    return source
}

/// Dimensions of the first image read from the header, without decoding pixels
private func pixelSize(of source: CGImageSource) -> (width: Int, height: Int)? {
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int,
          width > 0, height > 0 else {
        return nil
    }
    return (width, height)
}
