//
// DecryptFile.swift
// Proton Pass - Created on 10/12/2024.
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
import CryptoKit
import Entities
import Foundation

/// Symetrically decrypt the content of a file and save to a destination URL
public protocol DecryptFileUseCase: Sendable {
    func execute(key: Data, data: Data, destinationUrl: URL) async throws
}

public extension DecryptFileUseCase {
    func callAsFunction(key: Data, data: Data, destinationUrl: URL) async throws {
        try await execute(key: key, data: data, destinationUrl: destinationUrl)
    }
}

public final class DecryptFile: DecryptFileUseCase {
    public init() {}

    public func execute(key: Data, data: Data, destinationUrl: URL) async throws {
        let directory = destinationUrl.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let decryptedData = try AES.GCM.open(data, key: key, associatedData: .fileData)
        if !FileManager.default.createFile(atPath: destinationUrl.path(), contents: decryptedData) {
            throw PassError.fileAttachment(.failedToCreateFileOnFileSystem)
        }
    }
}
