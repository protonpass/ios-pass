//
// Gzip.swift
// Proton Pass - Created on 18/06/2026.
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

import Compression
import Foundation

enum GzipError: Error, Equatable {
    case notGzip
    case decodeFailed
    case checksumMismatch
}

extension Data {
    /// Decompresses a gzip (RFC 1952) payload.
    ///
    /// The compromised-password range files are served gzip-compressed (`*.gz`). Apple's
    /// `Compression` framework only decodes a *raw* DEFLATE stream with `COMPRESSION_ZLIB`
    /// (it does not understand the gzip wrapper), so we parse and strip the gzip header
    /// ourselves, inflate the DEFLATE payload via the streaming API (which, unlike the
    /// one-shot buffer API, handles an unknown decompressed size correctly), then validate the
    /// trailing CRC-32/ISIZE to catch silent corruption.
    func gunzipped() throws -> Data {
        let bytes = [UInt8](self)
        let payloadStart = try Self.gzipPayloadStart(bytes)

        // The 8-byte trailer (CRC32 + ISIZE) is left in: the DEFLATE decoder stops at the
        // end-of-stream marker and ignores any trailing bytes.
        let output = try subdata(in: payloadStart..<count).inflatedRawDeflate()

        // Validate the gzip trailer (RFC 1952): CRC-32 of the decompressed data and ISIZE
        // (uncompressed size mod 2³²), both little-endian.
        let last = bytes.count
        let expectedCRC = UInt32(bytes[last - 8]) | (UInt32(bytes[last - 7]) << 8)
            | (UInt32(bytes[last - 6]) << 16) | (UInt32(bytes[last - 5]) << 24)
        let expectedSize = UInt32(bytes[last - 4]) | (UInt32(bytes[last - 3]) << 8)
            | (UInt32(bytes[last - 2]) << 16) | (UInt32(bytes[last - 1]) << 24)
        guard UInt32(truncatingIfNeeded: output.count) == expectedSize,
              output.crc32() == expectedCRC else {
            throw GzipError.checksumMismatch
        }
        return output
    }

    /// CRC-32/ISO-HDLC (the variant gzip uses), computed bitwise — adequate for the small range
    /// payloads and avoids pulling in a zlib dependency.
    func crc32() -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in self {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB8_8320 : crc >> 1
            }
        }
        return ~crc
    }
}

private extension Data {
    /// Validates the gzip magic bytes/header (RFC 1952) and returns the index at which the DEFLATE
    /// payload begins, accounting for the optional FEXTRA/FNAME/FCOMMENT/FHCRC fields.
    static func gzipPayloadStart(_ bytes: [UInt8]) throws -> Int {
        // 10-byte header + at least 1 byte of payload + 8-byte trailer.
        guard bytes.count > 18 else { throw GzipError.notGzip }
        guard bytes[0] == 0x1F, bytes[1] == 0x8B, bytes[2] == 0x08 else {
            throw GzipError.notGzip
        }

        let flags = bytes[3]
        var index = 10

        // FEXTRA: 2-byte length + that many bytes.
        if flags & (1 << 2) != 0 {
            guard index + 2 <= bytes.count else { throw GzipError.notGzip }
            let xlen = Int(bytes[index]) | (Int(bytes[index + 1]) << 8)
            index += 2 + xlen
        }
        // FNAME / FCOMMENT: zero-terminated strings.
        for flag in [1 << 3, 1 << 4] where flags & UInt8(flag) != 0 {
            while index < bytes.count, bytes[index] != 0 {
                index += 1
            }
            index += 1
        }
        // FHCRC: 2-byte header CRC.
        if flags & (1 << 1) != 0 {
            index += 2
        }

        guard index < bytes.count - 8 else { throw GzipError.notGzip }
        return index
    }

    func inflatedRawDeflate() throws -> Data {
        let bufferSize = 32_768
        let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { dstBuffer.deallocate() }

        var stream = compression_stream(dst_ptr: dstBuffer,
                                        dst_size: bufferSize,
                                        src_ptr: UnsafePointer(dstBuffer),
                                        src_size: 0,
                                        state: nil)
        guard compression_stream_init(&stream,
                                      COMPRESSION_STREAM_DECODE,
                                      COMPRESSION_ZLIB) != COMPRESSION_STATUS_ERROR else {
            throw GzipError.decodeFailed
        }
        defer { compression_stream_destroy(&stream) }

        var output = Data()
        let failure: GzipError? = withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> GzipError? in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else {
                return .decodeFailed
            }
            stream.src_ptr = base
            stream.src_size = count
            stream.dst_ptr = dstBuffer
            stream.dst_size = bufferSize

            // All input is provided up front, so finalize in a single pass: the decoder returns
            // OK while the output buffer fills (drain and reset it) and END when the stream is done.
            let flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
            while true {
                switch compression_stream_process(&stream, flags) {
                case COMPRESSION_STATUS_OK:
                    if stream.dst_size == 0 {
                        output.append(dstBuffer, count: bufferSize)
                        stream.dst_ptr = dstBuffer
                        stream.dst_size = bufferSize
                    }

                case COMPRESSION_STATUS_END:
                    let produced = bufferSize - stream.dst_size
                    if produced > 0 {
                        output.append(dstBuffer, count: produced)
                    }
                    return nil

                default:
                    return .decodeFailed
                }
            }
        }
        if let failure {
            throw failure
        }
        return output
    }
}
