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
                 file: ItemFile,
                 progress: @Sendable @escaping (Float) -> Void) async throws -> URL
}

public extension DownloadAndDecryptFileUseCase {
    func callAsFunction(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile,
                        progress: @Sendable @escaping (Float) -> Void) async throws -> URL {
        try await execute(userId: userId, item: item, file: file, progress: progress)
    }
}

public final class DownloadAndDecryptFile: DownloadAndDecryptFileUseCase, @unchecked Sendable {
    private let generateFileTempUrl: any GenerateFileTempUrlUseCase
    private let keyManager: any PassKeyManagerProtocol
    private let apiService: any ApiServiceLiteProtocol

    public init(generateFileTempUrl: any GenerateFileTempUrlUseCase,
                keyManager: any PassKeyManagerProtocol,
                apiService: any ApiServiceLiteProtocol) {
        self.generateFileTempUrl = generateFileTempUrl
        self.keyManager = keyManager
        self.apiService = apiService
    }

    public func execute(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile,
                        progress: @Sendable @escaping (Float) -> Void) async throws -> URL {
        let fileManager = FileManager.default
        let url = try generateFileTempUrl(userId: userId, item: item, file: file)
        if fileManager.fileExists(atPath: url.path()) {
            // File already downloaded and cached
            return url
        }

        let itemKeys = try await keyManager.getItemKeys(userId: userId,
                                                        shareId: item.shareId,
                                                        itemId: item.itemId)

        guard let itemKey = itemKeys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
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
        defer { try? fileHandle.close() }

        var totalBytesDownloaded = 0
        let fileSize = max(1, file.size)

        for chunk in file.chunks {
            let path =
                "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/file/\(file.fileID)/chunk/\(chunk.chunkID)"
            let encryptedUrl = try await apiService.download(path: path,
                                                             userId: userId) { bytesDownloaded in
                totalBytesDownloaded += bytesDownloaded
                progress(Float(totalBytesDownloaded) / Float(fileSize))
            }
            let encryptedData = try Data(contentsOf: encryptedUrl)
            let decrypted = try AES.GCM.open(encryptedData,
                                             key: fileKey,
                                             associatedData: .fileData)
            try? fileManager.removeItem(atPath: encryptedUrl.path())
            try fileHandle.write(contentsOf: decrypted)
        }
        return url
    }
}
