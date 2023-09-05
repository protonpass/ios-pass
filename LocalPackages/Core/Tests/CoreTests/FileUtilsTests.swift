//
// FileUtilsTests.swift
// Proton Pass - Created on 16/04/2023.
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

@testable import Core
import XCTest

final class FileUtilsTests: XCTestCase {
    let containerUrl = FileUtils.getDocumentsDirectory()

    func testCreateNewFileWithData() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()

        // When
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)
        let data = try Data(contentsOf: fileUrl)

        // Then
        XCTAssertEqual(data, givenData)
    }

    func testCreateNewFileWithNullData() throws {
        // Given
        let givenFileName = String.random()

        // When
        let fileUrl = try FileUtils.createOrOverwrite(data: nil,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)
        let data = try Data(contentsOf: fileUrl)

        // Then
        XCTAssertTrue(data.isEmpty)
    }

    func testOverwriteData() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        try FileUtils.createOrOverwrite(data: nil,
                                        fileName: givenFileName,
                                        containerUrl: containerUrl)

        // When
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // Then
        let data = try Data(contentsOf: fileUrl)
        XCTAssertEqual(data, givenData)
    }

    func testGetCreationDate() throws {
        // Given
        let givenDate = Date.now
        let givenFileUrl = containerUrl.appendingPathComponent(.random())
        try FileManager.default.createFile(atPath: givenFileUrl.path,
                                           contents: .random(),
                                           attributes: [.creationDate: givenDate])

        // When
        let creationDate = try XCTUnwrap(FileUtils.getCreationDate(url: givenFileUrl))

        // Then
        XCTAssertEqual(creationDate, givenDate)
    }

    func testGetModificationDate() throws {
        // Given
        let givenDate = Date.now
        let givenFileUrl = containerUrl.appendingPathComponent(.random())
        try FileManager.default.createFile(atPath: givenFileUrl.path,
                                           contents: .random(),
                                           attributes: [.modificationDate: givenDate])

        // When
        let modificationDate = try XCTUnwrap(FileUtils.getModificationDate(url: givenFileUrl))

        // Then
        XCTAssertEqual(modificationDate, givenDate)
    }

    func testCheckObsolescences() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // Then
        XCTAssertFalse(FileUtils.isObsolete(url: fileUrl,
                                            currentDate: .now,
                                            thresholdInDays: 3))
        XCTAssertFalse(FileUtils.isObsolete(url: fileUrl,
                                            currentDate: .now.adding(component: .day,
                                                                     value: 1),
                                            thresholdInDays: 3))
        XCTAssertFalse(FileUtils.isObsolete(url: fileUrl,
                                            currentDate: .now.adding(component: .day,
                                                                     value: 2),
                                            thresholdInDays: 3))
        XCTAssertTrue(FileUtils.isObsolete(url: fileUrl,
                                           currentDate: .now.adding(component: .day,
                                                                    value: 3),
                                           thresholdInDays: 3))
    }

    func testGetValidData() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: fileUrl, isObsolete: false)

        // Then
        XCTAssertEqual(data, givenData)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path), "File still exists")
    }

    func testGetObsoleteData() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: fileUrl, isObsolete: true)

        // Then
        XCTAssertNil(data)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path), "File is removed")
    }

    func testGetDataOfNotExistFile() throws {
        // Given
        let givenUrl = containerUrl.appendingPathComponent(.random())

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: givenUrl, isObsolete: false)

        // Then
        XCTAssertNil(data)
    }
}
