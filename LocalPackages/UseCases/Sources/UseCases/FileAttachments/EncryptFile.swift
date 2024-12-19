//
// EncryptFile.swift
// Proton Pass - Created on 09/12/2024.
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

/// Symetrically encrypt a file at a given URL
public protocol EncryptFileUseCase: Sendable {
    func execute(key: Data, sourceUrl: URL) async throws -> Data
}

public extension EncryptFileUseCase {
    func callAsFunction(key: Data, sourceUrl: URL) async throws -> Data {
        try await execute(key: key, sourceUrl: sourceUrl)
    }
}

public final class EncryptFile: EncryptFileUseCase {
    public init() {}

    public func execute(key: Data, sourceUrl: URL) async throws -> Data {
        let data = try Data(contentsOf: sourceUrl)
        guard let encryptedData = try AES.GCM.seal(data,
                                                   key: key,
                                                   associatedData: .fileData).combined else {
            throw PassError.fileAttachment(.failedToEncryptFile)
        }
        return encryptedData
    }
}
