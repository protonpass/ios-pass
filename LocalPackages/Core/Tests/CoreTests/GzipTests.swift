//  
// GzipTests.swift
// Proton Pass - Created on 07/07/2026.
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

@testable import Core
import Compression
import Foundation
import Testing

@Suite
struct GzipTests {
    @Test
    func `Round-trips a gzip payload`() throws {
        let original = """
        0000000000000000000000000000000000:3
        7D0679CA88DB6464EAC60DA96345513964:31033620
        """
        let result = try makeGzip(original).gunzipped()
        #expect(String(decoding: result, as: UTF8.self) == original)
    }

    @Test
    func `Round-trips a payload larger than the inflate buffer`() throws {
        // Force several drain cycles through the 32k streaming buffer.
        let original = String(repeating: "ABCDEF0123456789:42\n", count: 5_000)
        let result = try makeGzip(original).gunzipped()
        #expect(String(decoding: result, as: UTF8.self) == original)
    }

    @Test
    func `Rejects non-gzip data`() {
        #expect(throws: GzipError.notGzip) {
            try Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
                      0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10,
                      0x11, 0x12, 0x13, 0x14]).gunzipped()
        }
    }

    @Test
    func `Rejects a payload with a corrupted CRC trailer`() {
        var corrupted = makeGzip("7D0679CA88DB6464EAC60DA96345513964:31033620\n")
        corrupted[corrupted.count - 8] ^= 0xFF // flip a CRC-32 trailer byte
        #expect(throws: GzipError.checksumMismatch) {
            try corrupted.gunzipped()
        }
    }
}

/// Builds a valid gzip container (RFC 1952) around `string`, including the CRC-32/ISIZE trailer
/// that `gunzipped()` validates.
private func makeGzip(_ string: String) -> Data {
    let payload = Data(string.utf8)
    var gzip = Data([0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF])
    gzip.append(rawDeflate(payload))
    let crc = payload.crc32()
    let isize = UInt32(truncatingIfNeeded: payload.count)
    for value in [crc, isize] {
        gzip.append(contentsOf: (0 ..< 4).map { UInt8((value >> ($0 * 8)) & 0xFF) })
    }
    return gzip
}

private func rawDeflate(_ data: Data) -> Data {
    let capacity = data.count * 2 + 256
    let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
    defer { dst.deallocate() }
    let written = data.withUnsafeBytes { raw -> Int in
        guard let base = raw.bindMemory(to: UInt8.self).baseAddress else {
            return 0
        }
        return compression_encode_buffer(dst, capacity, base, data.count, nil, COMPRESSION_ZLIB)
    }
    return Data(bytes: dst, count: written)
}
