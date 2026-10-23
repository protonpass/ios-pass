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
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct DownloadAndDecryptFileTests {
    let url = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString)
        .appending(path: "file.bin")
    let itemKeyData = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    let fileKey = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    let item = TestItem(shareId: .random(), itemId: .random())

    @Test(arguments: [
        "report.pdf",
        "My report [final] #2 100%.pdf",
        "café.txt",
        "Lønseddel.pdf",
        "Driver’s license.pdf",
        "Notes – draft….txt",
        "Screenshot 2026-10-05 at 1.47.07\u{202F}PM.png",
        "测试报告.txt",
        "ハ\u{3099}ックアッフ\u{309A}.png",
        "사업자등록증.jpg",
        "נספח.docx"
    ])
    func `downloads and decrypts a file under its original name`(fileName: String) async throws {
        // Given
        let context = try DownloadContext(fileName: fileName)
        defer { context.removeDownloads() }

        // When
        let url = try await context.download()

        // Then
        #expect(url.lastPathComponent == fileName)
        #expect(try Data(contentsOf: url) == context.content)
    }

    @Test(arguments: ["report.pdf", "测试报告.txt", "Screenshot 2026-10-05 at 1.47.07\u{202F}PM.png"])
    func `reuses an already downloaded file instead of downloading it again`(fileName: String) async throws {
        // Given
        let context = try DownloadContext(fileName: fileName)
        defer { context.removeDownloads() }
        let firstUrl = try await context.download()

        // When
        let secondUrl = try await context.download()

        // Then
        #expect(secondUrl == firstUrl)
        #expect(await context.shareRepository.invokedGetShareCount == 1)
    }

    @Test func `A failed chunk download removes the partial file`() async throws {
        defer { removeDownloads() }
        let file = try makeFile(chunkCount: 2)
        let firstChunk = try encryptedChunk(index: 0, chunkCount: 2)
        let sut = makeSut(file: file) { chunkID in
            AsyncThrowingStream { continuation in
                if chunkID == "0" {
                    continuation.yield(.result(firstChunk))
                    continuation.finish()
                } else {
                    continuation.finish(throwing: URLError(.notConnectedToInternet))
                }
            }
        }

        let stream = try await sut(userId: .random(), item: item, file: file)

        await #expect(throws: URLError.self) {
            for try await _ in stream {}
        }
        #expect(!FileManager.default.fileExists(atPath: url.path()))
    }

    @Test func `A cancelled download stops and removes the partial file`() async throws {
        defer { removeDownloads() }
        let file = try makeFile(chunkCount: 3)
        let firstChunk = try encryptedChunk(index: 0, chunkCount: 3)
        let (secondChunkRequested, secondChunkRequestedContinuation) = AsyncStream<Void>.makeStream()
        let sut = makeSut(file: file) { chunkID in
            AsyncThrowingStream { continuation in
                switch chunkID {
                case "0":
                    continuation.yield(.result(firstChunk))
                    continuation.finish()
                case "1":
                    secondChunkRequestedContinuation.yield()
                default:
                    Issue.record("Chunk \(chunkID) requested after the cancellation")
                }
            }
        }

        let stream = try await sut(userId: .random(), item: item, file: file)
        let consumer = Task { for try await _ in stream {} }
        for await _ in secondChunkRequested {
            break
        }
        consumer.cancel()

        try await waitUntil { !FileManager.default.fileExists(atPath: url.path()) }
    }
}

private extension DownloadAndDecryptFileTests {
    func makeSut(file: ItemFile,
                 download: @escaping @Sendable (String) -> AsyncThrowingStream<ProgressEvent<Data>, any Error>)
        -> DownloadAndDecryptFile {
        let keyManager = PassKeyManagerProtocolMock()
        keyManager.stubbedGetShareKeysResult = [DecryptedItemKey(containerId: item.shareId,
                                                                 itemId: item.itemId,
                                                                 keyRotation: Int64(file.itemKeyRotation),
                                                                 keyData: itemKeyData)]
        let shareRepository = ShareRepositoryProtocolMock()
        shareRepository.stubbedGetShareResult = .random()
        return DownloadAndDecryptFile(generateFileTempUrl: FileTempUrlStub(url: url),
                                      shareRepository: shareRepository,
                                      keyManager: keyManager,
                                      apiService: ApiServiceLiteStub(download: download))
    }

    func makeFile(chunkCount: Int) throws -> ItemFile {
        let chunksJson = (0..<chunkCount)
            .map { #"{"chunkID":"\#($0)","index":\#($0),"size":100}"# }
            .joined(separator: ",")
        let chunks = try JSONDecoder().decode([FileChunk].self, from: Data("[\(chunksJson)]".utf8))
        let encryptedFileKey = try AES.GCM.seal(fileKey, key: itemKeyData, associatedData: .fileKey)
        return .random(fileID: .random(),
                       size: 100 * chunkCount,
                       fileKey: encryptedFileKey.base64EncodedString(),
                       itemKeyRotation: 1,
                       chunks: chunks,
                       encryptionVersion: 1)
    }

    func encryptedChunk(index: Int, chunkCount: Int) throws -> Data {
        try AES.GCM.seal(Data(repeating: 1, count: 100),
                         key: fileKey,
                         associatedData: .fileData(version: 1, chunkIndex: index, chunkCount: chunkCount))
    }

    func removeDownloads() {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    func waitUntil(_ condition: () -> Bool) async throws {
        var attempts = 0
        while !condition(), attempts < 200 {
            attempts += 1
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(condition())
    }
}

private struct FileTempUrlStub: GenerateFileTempUrlUseCase {
    let url: URL

    func execute(userId: String, item: any ItemIdentifiable, file: ItemFile) throws -> URL {
        url
    }
}

private struct ApiServiceLiteStub: ApiServiceLiteProtocol {
    let download: @Sendable (String) -> AsyncThrowingStream<ProgressEvent<Data>, any Error>

    func uploadMultipart<R: Decodable & Sendable>(path: String,
                                                  userId: String,
                                                  infos: [MultipartInfo]) throws
        -> AsyncThrowingStream<ProgressEvent<R>, any Error> {
        AsyncThrowingStream { $0.finish() }
    }

    func download(path: String, userId: String) throws
        -> AsyncThrowingStream<ProgressEvent<Data>, any Error> {
        download(String(path.split(separator: "/").last ?? ""))
    }
}

private struct DownloadContext {
    let content = Data("Proton Pass".utf8)
    let userId = String.random()
    let item = DummyItemIdentifiable(itemId: .random(), shareId: .random())
    let file: ItemFile
    let shareRepository = ShareRepositoryProtocolMock()
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "DownloadAndDecryptFileTests")
        .appending(path: UUID().uuidString)
    let sut: DownloadAndDecryptFile

    init(fileName: String) throws {
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
        self.file = file

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
        sut = DownloadAndDecryptFile(generateFileTempUrl: IsolatedFileTempUrl(directory: directory),
                                     shareRepository: shareRepository,
                                     keyManager: keyManager,
                                     apiService: ChunkApiServiceLite(chunk: encryptedChunk))
    }

    func download() async throws -> URL {
        var url: URL?
        for try await event in try await sut(userId: userId, item: item, file: file) {
            if case let .result(value) = event {
                url = value
            }
        }
        return try #require(url)
    }

    func removeDownloads() {
        try? FileManager.default.removeItem(at: directory)
    }
}

/// Kept out of the real attachment root: `ClearCacheForLoggedOutUsersTests` runs in parallel
/// and deletes every user folder there that its stubbed users don't own
private struct IsolatedFileTempUrl: GenerateFileTempUrlUseCase {
    let directory: URL

    func execute(userId: String, item: any ItemIdentifiable, file: ItemFile) -> URL {
        directory.appendingPathComponent(SanitizeFileName()(file.name ?? ""), conformingTo: .data)
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
