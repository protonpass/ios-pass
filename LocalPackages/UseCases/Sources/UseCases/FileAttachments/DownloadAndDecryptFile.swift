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

public final class DownloadAndDecrypt: DownloadAndDecryptFileUseCase {
    private let keyManager: any PassKeyManagerProtocol
    private let remoteDatasource: any RemoteFileDatasourceProtocol
    private let decryptFile: any DecryptFileUseCase

    public init(keyManager: any PassKeyManagerProtocol,
                remoteDatasource: any RemoteFileDatasourceProtocol,
                decryptFile: any DecryptFileUseCase) {
        self.keyManager = keyManager
        self.remoteDatasource = remoteDatasource
        self.decryptFile = decryptFile
    }

    public func execute(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) async throws -> URL {
        guard let chunkId = file.chunks.first?.chunkID else {
            throw PassError.fileAttachment(.noChunkId(file.fileID))
        }

        guard let name = file.name else {
            throw PassError.fileAttachment(.failedToDownloadMissingFileName(file.fileID))
        }

        let filePath =
            "\(userId)/\(item.shareId)/\(item.itemId)/\(file.fileID)/\(file.modifyTime)/\(name))"
        let url = FileManager.default.temporaryDirectory.appending(path: filePath)

        if FileManager.default.fileExists(atPath: url.path()) {
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

        let encryptedFileData = try await remoteDatasource.getChunkContent(userId: userId,
                                                                           item: item,
                                                                           fileId: file.fileID,
                                                                           chunkId: chunkId)

        try await decryptFile(key: fileKey, data: encryptedFileData, destinationUrl: url)
        return url
    }
}
