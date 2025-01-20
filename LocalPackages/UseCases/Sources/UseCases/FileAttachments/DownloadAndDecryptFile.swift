//
// DownloadAndDecryptFile.swift
// Proton Pass - Created on 17/12/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Client
import Core
import CryptoKit
import Entities
import Foundation

public protocol DownloadAndDecryptFileUseCase: Sendable {
    func execute(userId: String,
                 item: any ItemIdentifiable,
                 file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error>
}

public extension DownloadAndDecryptFileUseCase {
    func callAsFunction(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error> {
        try await execute(userId: userId, item: item, file: file)
    }
}

public actor DownloadAndDecryptFile: DownloadAndDecryptFileUseCase {
    private let generateFileTempUrl: any GenerateFileTempUrlUseCase
    private let shareRepository: any ShareRepositoryProtocol
    private let keyManager: any PassKeyManagerProtocol
    private let apiService: any ApiServiceLiteProtocol

    public init(generateFileTempUrl: any GenerateFileTempUrlUseCase,
                shareRepository: any ShareRepositoryProtocol,
                keyManager: any PassKeyManagerProtocol,
                apiService: any ApiServiceLiteProtocol) {
        self.generateFileTempUrl = generateFileTempUrl
        self.keyManager = keyManager
        self.shareRepository = shareRepository
        self.apiService = apiService
    }

    public func execute(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) async throws
        -> AsyncThrowingStream<ProgressEvent<URL>, any Error> {
        let fileManager = FileManager.default
        let url = try generateFileTempUrl(userId: userId, item: item, file: file)
        if fileManager.fileExists(atPath: url.path()),
           let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let fileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.intValue,
           // Heuristically make sure downloaded decrypted file size is >= 98% of the encrypted size
           // to make sure file is fully downloaded. Because we download, decrypt and write
           // chunk by chunk so file could be corrupted even though it exists
           (file.size == 0) || (fileSize >= file.size * 98 / 100) {
            return .init { continuation in
                continuation.yield(.result(url))
                continuation.finish()
            }
        }
        guard let share = try await shareRepository.getShare(shareId: item.shareId) else {
            throw PassError.shareNotFoundInLocalDB(shareID: item.shareId)
        }

        let keys = try await keyManager.getShareKeys(userId: userId,
                                                     share: share,
                                                     item: item)

        guard let itemKey = keys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
            throw PassError.fileAttachment(.missingItemKey(file.itemKeyRotation))
        }

        guard let encryptedFileKey = try file.fileKey.base64Decode() else {
            throw PassError.fileAttachment(.failedToDownloadMissingDecryptedFileKey(file.fileID))
        }

        let fileKey = try AES.GCM.open(encryptedFileKey,
                                       key: itemKey.keyData,
                                       associatedData: .fileKey)

        // Create the empty file
        try fileManager.createDirectory(at: url.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
        fileManager.createFile(atPath: url.path(), contents: nil)

        // Download, decrypt and write to file chunk by chunk
        let fileHandle = try FileHandle(forWritingTo: url)
        let tracker = FileProgressTracker(size: file.size)

        return .asyncContinuation { [weak self] continuation in
            defer { try? fileHandle.close() }
            guard let self else {
                continuation.finish(throwing: PassError.deallocatedSelf)
                return
            }
            for chunk in file.chunks {
                let path =
                    "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/file/\(file.fileID)/chunk/\(chunk.chunkID)"
                let stream = try await apiService.download(path: path,
                                                           userId: userId)
                for try await event in stream {
                    switch event {
                    case let .progress(value):
                        let overall = await tracker.overallProgress(currentProgress: value,
                                                                    chunkSize: chunk.size)
                        continuation.yield(.progress(overall))
                    case let .result(encryptedData):
                        let decrypted = try AES.GCM.open(encryptedData,
                                                         key: fileKey,
                                                         associatedData: .fileData)
                        try fileHandle.write(contentsOf: decrypted)
                    }
                }
            }
            continuation.yield(.result(url))
            continuation.finish()
        }
    }
}
