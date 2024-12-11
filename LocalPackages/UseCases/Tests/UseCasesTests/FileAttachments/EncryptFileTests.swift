//
// EncryptFileTests.swift
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
import Foundation
import Testing
import UseCases

struct EncryptFileTests {
    let sut: any EncryptFileUseCase

    init() {
        sut = EncryptFile()
    }

    @Test("Encrypt file")
    func encrypt() async throws {
        // Given
        let key = try Data.random()
        let data = try Data.random(byteCount: 10 * 1_024 * 1_024) // 10 MB
        let sourceUrl = FileManager.default.temporaryDirectory.appending(path: "plain.data")
        FileManager.default.createFile(atPath: sourceUrl.path(), contents: data)

        // When
        let encryptedData = try await sut(key: key, sourceUrl: sourceUrl)
        let decryptedData = try AES.GCM.open(encryptedData, key: key, associatedData: .fileData)

        // Then
        #expect(decryptedData == data)
    }
}
