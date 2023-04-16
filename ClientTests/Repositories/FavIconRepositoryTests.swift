//
// FavIconRepositoryTests.swift
// Proton Pass - Created on 14/04/2023.
// Copyright (c) 2023 Proton Technologies AG
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

// swiftlint:disable force_try
@testable import Client
import Core
import ProtonCore_Services
import XCTest

final class FavIconRepositoryTests: XCTestCase {
    var sut: FavIconRepositoryProtocol!

    override func setUp() {
        super.setUp()
        let documentDirectory = FileUtils.getDocumentsDirectory()
        let containerUrl = documentDirectory.appendingPathComponent("FavIcons",
                                                                    isDirectory: true)
        sut = FavIconRepository(apiService: PMAPIService.dummyService(),
                                containerUrl: containerUrl,
                                cacheExpirationDays: 14,
                                domainParser: try! .init(),
                                symmetricKey: .random())
        try? sut.emptyCache()
    }

    override func tearDown() {
        try? sut.emptyCache()
        sut = nil
        super.tearDown()
    }
}

extension FavIconRepositoryTests {
    func testGetAllCachedIcons() throws {
        // Given
        let key = sut.symmetricKey
        let containerUrl = sut.containerUrl

        let random: (String) throws -> FavIconData = { domain in
            let type: FavIconData.`Type` = Bool.random() ? .negative : .positive

            let data: Data?
            let fileName: String
            switch type {
            case .positive:
                data = .random()
                fileName = try FavIconCacheUtils.positiveFileName(for: domain,
                                                                  with: key)
            case .negative:
                data = nil
                fileName = try FavIconCacheUtils.negativeFileName(for: domain,
                                                                  with: key)
            }

            try FileUtils.createOrOverwrite(data: data, fileName: fileName, containerUrl: containerUrl)
            return .init(domain: domain, data: data, type: type)
        }

        let givenCachedItems = try Array(repeating: 0, count: .random(in: 10...100)).map { _ in
            try random(.random())
        }

        // Dummy files
        for _ in 0..<100 {
            try FileUtils.createOrOverwrite(data: .random(),
                                            fileName: .random(),
                                            containerUrl: containerUrl)
        }

        // When
        let icons = try sut.getAllCachedIcons()

        // Then
        XCTAssertEqual(icons.count, givenCachedItems.count)
        for item in givenCachedItems {
            XCTAssertTrue(icons.contains(item))
        }
    }
}

// MARK: - FavIconCacheUtils test
extension FavIconRepositoryTests {
    func testEncryptionAndDecryption() throws {
        // Given
        let key = sut.symmetricKey
        let givenClearText = String.random()

        // When
        let encryptedText = try FavIconCacheUtils.encryptAndBase64(text: givenClearText,
                                                                   with: key)
        let decryptedText = try FavIconCacheUtils.decrypt(base64: encryptedText, with: key)

        // Then
        XCTAssertEqual(decryptedText, givenClearText)
    }
}
