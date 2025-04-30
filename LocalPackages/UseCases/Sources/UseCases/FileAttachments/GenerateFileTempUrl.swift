//
// GenerateFileTempUrl.swift
// Proton Pass - Created on 23/12/2024.
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

import Core
import Entities
import Foundation

public protocol GenerateFileTempUrlUseCase: Sendable {
    func execute(userId: String,
                 item: any ItemIdentifiable,
                 file: ItemFile) throws -> URL
}

public extension GenerateFileTempUrlUseCase {
    func callAsFunction(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) throws -> URL {
        try execute(userId: userId, item: item, file: file)
    }
}

public final class GenerateFileTempUrl: GenerateFileTempUrlUseCase {
    private let sanitizeFileName: any SanitizeFileNameUseCase

    public init(sanitizeFileName: any SanitizeFileNameUseCase) {
        self.sanitizeFileName = sanitizeFileName
    }

    public func execute(userId: String,
                        item: any ItemIdentifiable,
                        file: ItemFile) throws -> URL {
        guard let name = file.name else {
            throw PassError.fileAttachment(.failedToDownloadMissingFileName(file.fileID))
        }
        let sanitizedName = sanitizeFileName(name)
        return FileManager.default.temporaryDirectory
            .appending(path: Constants.Attachment.rootDirectoryName)
            .appending(path: userId)
            .appending(path: item.shareId)
            .appending(path: item.itemId)
            .appending(path: file.fileID)
            .appending(path: "\(file.modifyTime)")
            .appendingPathComponent(sanitizedName, conformingTo: .data)
    }
}
