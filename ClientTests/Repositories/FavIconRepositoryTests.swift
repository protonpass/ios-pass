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

@testable import Client
import ProtonCore_Services
import XCTest

final class FavIconRepositoryTests: XCTestCase {
    var sut: FavIconRepositoryProtocol!

    override func setUp() {
        super.setUp()
        sut = FavIconRepository(apiService: PMAPIService.dummyService(),
                                containerUrl: getDocumentsDirectory(),
                                cacheExpirationDays: 14,
                                symmetricKey: .random())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

// MARK: - FavIconCacheUtils test
extension FavIconRepositoryTests {
    func testEncryptDomains() throws {
        let test: (String, String) throws -> Void = { [self] inputDomain, outputDomain in
            let key = sut.symmetricKey
            let encryptedDomain = try FavIconCacheUtils.encrypt(domain: inputDomain,
                                                                with: key)
            let decryptedDomain = try key.decrypt(encryptedDomain)
            XCTAssertEqual(decryptedDomain, outputDomain)
        }
        try test("proton.me", "proton.me")
        try test("https://proton.me", "proton.me")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("http://proton.me/path/to/sth", "proton.me")
        try test("proton.me/path/to/sth", "proton.me/path/to/sth")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("https://proton.me/blog/lessons-from-lastpass#protect", "proton.me")
    }

    func testGeneratePositiveFileNames() throws {
        let test: (String, String) throws -> Void = { [self] inputDomain, outputDomain in
            let key = sut.symmetricKey
            let fullName = try FavIconCacheUtils.positiveFileName(for: inputDomain,
                                                                  with: key)
            let components = fullName.components(separatedBy: ".")

            XCTAssertEqual(components.count, 2)

            let encryptedFileName = try XCTUnwrap(components.first)
            let decryptedFileName = try key.decrypt(encryptedFileName)
            XCTAssertEqual(decryptedFileName, outputDomain)

            let `extension` = try XCTUnwrap(components.last)
            XCTAssertEqual(`extension`, "positive")
        }
        try test("proton.me", "proton.me")
        try test("https://proton.me", "proton.me")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("http://proton.me/path/to/sth", "proton.me")
        try test("proton.me/path/to/sth", "proton.me/path/to/sth")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("https://proton.me/blog/lessons-from-lastpass#protect", "proton.me")
    }

    func testGenerateNegativeFileNames() throws {
        let test: (String, String) throws -> Void = { [self] inputDomain, outputDomain in
            let key = sut.symmetricKey
            let fullName = try FavIconCacheUtils.negativeFileName(for: inputDomain,
                                                                  with: key)
            let components = fullName.components(separatedBy: ".")

            XCTAssertEqual(components.count, 2)

            let encryptedFileName = try XCTUnwrap(components.first)
            let decryptedFileName = try key.decrypt(encryptedFileName)
            XCTAssertEqual(decryptedFileName, outputDomain)

            let `extension` = try XCTUnwrap(components.last)
            XCTAssertEqual(`extension`, "negative")
        }
        try test("proton.me", "proton.me")
        try test("https://proton.me", "proton.me")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("http://proton.me/path/to/sth", "proton.me")
        try test("proton.me/path/to/sth", "proton.me/path/to/sth")
        try test("https://proton.me/path/to/sth", "proton.me")
        try test("https://proton.me/blog/lessons-from-lastpass#protect", "proton.me")
    }

    func testCacheNotNullData() throws {
        // Given
        let givenContainerUrl = getDocumentsDirectory()
        let givenData = Data.random()
        let givenFileName = String.random()
        try FavIconCacheUtils.cache(data: givenData,
                                    fileName: givenFileName,
                                    containerUrl: givenContainerUrl)

        // When
        let fileUrl = givenContainerUrl.appendingPathComponent(givenFileName,
                                                               conformingTo: .data)
        let data = try Data(contentsOf: fileUrl)

        // Then
        XCTAssertEqual(data, givenData)
    }

    func testCacheNullData() throws {
        // Given
        let givenContainerUrl = getDocumentsDirectory()
        let givenFileName = String.random()
        try FavIconCacheUtils.cache(data: nil,
                                    fileName: givenFileName,
                                    containerUrl: givenContainerUrl)

        // When
        let fileUrl = givenContainerUrl.appendingPathComponent(givenFileName,
                                                               conformingTo: .data)
        let data = try Data(contentsOf: fileUrl)

        // Then
        XCTAssertTrue(data.isEmpty)
    }

    func testGetValidData() throws {
        // Given
        let givenContainerUrl = getDocumentsDirectory()
        let givenFileName = String.random()
        let givenData = Data.random()
        try FavIconCacheUtils.cache(data: givenData,
                                    fileName: givenFileName,
                                    containerUrl: givenContainerUrl)

        // When
        var data = try FavIconCacheUtils.getDataRemovingIfObsolete(fileName: givenFileName,
                                                                   containerUrl: givenContainerUrl,
                                                                   isObsolete: false)

        // Then
        data = try XCTUnwrap(data)
        XCTAssertEqual(data, givenData)

        let fileUrl = givenContainerUrl.appendingPathComponent(givenFileName, conformingTo: .data)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path), "File still exists")
    }

    func testGetObsoleteData() throws {
        // Given
        let givenContainerUrl = getDocumentsDirectory()
        let givenFileName = String.random()
        let givenData = Data.random()
        try FavIconCacheUtils.cache(data: givenData,
                                    fileName: givenFileName,
                                    containerUrl: givenContainerUrl)

        // When
        let data = try FavIconCacheUtils.getDataRemovingIfObsolete(fileName: givenFileName,
                                                                   containerUrl: givenContainerUrl,
                                                                   isObsolete: true)

        // Then
        XCTAssertNil(data)

        let fileUrl = givenContainerUrl.appendingPathComponent(givenFileName, conformingTo: .data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path), "File is deleted")
    }

    func testCheckObsolescences() throws {
        // Given
        let givenContainerUrl = getDocumentsDirectory()
        let givenFileName = String.random()
        let givenData = Data.random()
        try FavIconCacheUtils.cache(data: givenData,
                                    fileName: givenFileName,
                                    containerUrl: givenContainerUrl)

        // Then
        XCTAssertFalse(FavIconCacheUtils.isObsolete(fileName: givenFileName,
                                                    containerUrl: givenContainerUrl,
                                                    currentDate: .now,
                                                    thresholdInDays: 3))
        XCTAssertFalse(FavIconCacheUtils.isObsolete(fileName: givenFileName,
                                                    containerUrl: givenContainerUrl,
                                                    currentDate: .now.adding(component: .day,
                                                                             value: 1),
                                                    thresholdInDays: 3))
        XCTAssertFalse(FavIconCacheUtils.isObsolete(fileName: givenFileName,
                                                    containerUrl: givenContainerUrl,
                                                    currentDate: .now.adding(component: .day,
                                                                             value: 2),
                                                    thresholdInDays: 3))
        XCTAssertTrue(FavIconCacheUtils.isObsolete(fileName: givenFileName,
                                                   containerUrl: givenContainerUrl,
                                                   currentDate: .now.adding(component: .day,
                                                                            value: 3),
                                                   thresholdInDays: 3))
    }
}

private func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}
