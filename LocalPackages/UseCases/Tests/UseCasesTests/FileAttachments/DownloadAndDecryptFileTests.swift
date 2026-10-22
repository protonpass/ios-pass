//
// DownloadAndDecryptFileTests.swift
// Proton Pass - Created on 22/10/2026.
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

import Client
import ClientMocks
import Core
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct DownloadAndDecryptFileTests {
    @Test(arguments: ["report.pdf", "测试报告.txt", "נספח.docx", "café.txt", "My report [final] #2 100%.pdf"])
    func `downloads and decrypts a file under its original name`(fileName: String) async throws {
        // Given
        let content = Data("Proton Pass".utf8)
        let itemKey = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        let fileKey = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        let chunk = try JSONDecoder().decode(FileChunk.self,
                                             from: Data(#"{"chunkID":"c","index":0,"size":1}"#.utf8))
        var file = try ItemFile.random(fileID: .random(),
                                       size: content.count,
                                       fileKey: AES.GCM.seal(fileKey, key: itemKey, associatedData: .fileKey)
                                           .base64EncodedString(),
                                       chunks: [chunk],
                                       encryptionVersion: 1)
        file.name = fileName
        let item = DummyItemIdentifiable(itemId: .random(), shareId: .random())

        let shareRepository = ShareRepositoryProtocolMock()
        shareRepository.stubbedGetShareResult = .random(shareID: item.shareId)
        let keyManager = PassKeyManagerProtocolMock()
        keyManager.stubbedGetShareKeysResult = [
            DecryptedShareKey(shareId: item.shareId,
                              keyRotation: Int64(file.itemKeyRotation),
                              keyData: itemKey)
        ]
        let encryptedChunk = try AES.GCM.seal(content,
                                              key: fileKey,
                                              associatedData: .fileData(version: 1, chunkIndex: 0, chunkCount: 1))
        let userId = String.random()
        let sut =
            DownloadAndDecryptFile(generateFileTempUrl: GenerateFileTempUrl(sanitizeFileName: SanitizeFileName()),
                                   shareRepository: shareRepository,
                                   keyManager: keyManager,
                                   apiService: ChunkApiServiceLite(chunk: encryptedChunk))
        defer {
            try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory
                .appending(path: Constants.Attachment.rootDirectoryName)
                .appending(path: userId))
        }

        // When
        var url: URL?
        for try await event in try await sut(userId: userId, item: item, file: file) {
            if case let .result(value) = event {
                url = value
            }
        }

        // Then
        let fileUrl = try #require(url)
        #expect(fileUrl.lastPathComponent == fileName)
        #expect(try Data(contentsOf: fileUrl) == content)
    }
}

private struct ChunkApiServiceLite: ApiServiceLiteProtocol {
    let chunk: Data

    func uploadMultipart<R: Decodable>(path: String,
                                       userId: String,
                                       infos: [MultipartInfo])
        -> AsyncThrowingStream<ProgressEvent<R>, any Error> {
        .init { $0.finish() }
    }

    func download(path: String, userId: String)
        -> AsyncThrowingStream<ProgressEvent<Data>, any Error> {
        .init { continuation in
            continuation.yield(.result(chunk))
            continuation.finish()
        }
    }
}
