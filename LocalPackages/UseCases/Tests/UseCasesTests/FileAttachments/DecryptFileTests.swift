//
// DecryptFileTests.swift
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
import Foundation
import Testing
import UseCases

struct DecryptFileTests {
    let sut: any DecryptFileUseCase

    init() {
        sut = DecryptFile()
    }

    @Test("Decrypt file")
    func decrypt() async throws {
        // Given
        let key = try Data.random()
        let data = try Data.random(byteCount: 10 * 1_024 * 1_024) // 10 MB
        let encryptedData = try AES.GCM.seal(data, key: key, associatedData: .fileData)
        let sourceUrl = FileManager.default.temporaryDirectory.appending(path: "encrypted.data")
        FileManager.default.createFile(atPath: sourceUrl.path(), contents: encryptedData.combined)

        let destinationUrl = FileManager.default.temporaryDirectory.appending(path: "plain.data")

        // When
        try await sut(key: key, sourceUrl: sourceUrl, destinationUrl: destinationUrl)

        let decryptedData = try Data(contentsOf: destinationUrl)

        // Then
        #expect(decryptedData == data)
    }
}
