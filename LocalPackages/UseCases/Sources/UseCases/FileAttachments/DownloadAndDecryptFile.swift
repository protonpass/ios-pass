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
                 file: ItemFile) async throws -> URL
}

public extension DownloadAndDecryptFileUseCase {
    func callAsFunction(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) async throws -> URL {
        try await execute(userId: userId, item: item, file: file)
    }
}

public final class DownloadAndDecryptFile: DownloadAndDecryptFileUseCase {
    private let keyManager: any PassKeyManagerProtocol
    private let remoteDatasource: any RemoteFileDatasourceProtocol

    public init(keyManager: any PassKeyManagerProtocol,
                remoteDatasource: any RemoteFileDatasourceProtocol) {
        self.keyManager = keyManager
        self.remoteDatasource = remoteDatasource
    }

    public func execute(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) async throws -> URL {
        guard let name = file.name else {
            throw PassError.fileAttachment(.failedToDownloadMissingFileName(file.fileID))
        }

        let fileManager = FileManager.default

        let url = fileManager.temporaryDirectory
            .appending(path: userId)
            .appending(path: item.shareId)
            .appending(path: item.itemId)
            .appending(path: file.fileID)
            .appending(path: "\(file.modifyTime)")
            .appendingPathComponent(name, conformingTo: .data)

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
        for chunk in file.chunks {
            let encrypted = try await remoteDatasource.getChunkContent(userId: userId,
                                                                       item: item,
                                                                       fileId: file.fileID,
                                                                       chunkId: chunk.chunkID)
            let decrypted = try AES.GCM.open(encrypted,
                                             key: fileKey,
                                             associatedData: .fileData)
            try fileHandle.write(contentsOf: decrypted)
        }
        return url
    }
}
