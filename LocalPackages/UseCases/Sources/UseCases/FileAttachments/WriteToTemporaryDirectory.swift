//
// WriteToTemporaryDirectory.swift
// Proton Pass - Created on 28/11/2024.
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

public protocol WriteToTemporaryDirectoryUseCase: Sendable {
    @discardableResult
    func execute(data: Data,
                 fileName: String,
                 maxFileSize: UInt64) throws -> URL
}

public extension WriteToTemporaryDirectoryUseCase {
    @discardableResult
    func callAsFunction(data: Data,
                        fileName: String,
                        maxFileSize: UInt64 = Constants.Utils.maxFileSizeInBytes) throws -> URL {
        try execute(data: data, fileName: fileName, maxFileSize: maxFileSize)
    }
}

public final class WriteToTemporaryDirectory: WriteToTemporaryDirectoryUseCase {
    private let writeToUrl: any WriteToUrlUseCase

    public init(writeToUrl: any WriteToUrlUseCase) {
        self.writeToUrl = writeToUrl
    }

    public func execute(data: Data,
                        fileName: String,
                        maxFileSize: UInt64) throws -> URL {
        let fileSize = UInt64(data.count)
        guard fileSize < maxFileSize else {
            throw PassError.fileAttachment(.fileTooLarge(fileSize))
        }
        return try writeToUrl(data: data,
                              fileName: fileName,
                              baseUrl: FileManager.default.temporaryDirectory)
    }
}
