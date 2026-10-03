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

import Core
import Foundation
import Testing

@Suite(.tags(.utilities))
struct FileUtilsTests {
    let containerUrl = FileUtils.getDocumentsDirectory()

    @Test func `create new file with data`() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()

        // When
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)
        let data = try Data(contentsOf: fileUrl)

        // Then
        #expect(data == givenData)
    }

    @Test func `create new file with null data`() throws {
        // Given
        let givenFileName = String.random()

        // When
        let fileUrl = try FileUtils.createOrOverwrite(data: nil,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)
        let data = try Data(contentsOf: fileUrl)

        // Then
        #expect(data.isEmpty)
    }

    @Test func `overwrite data`() throws {
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
        #expect(data == givenData)
    }

    @Test func `get creation date`() throws {
        // Given
        let givenDate = Date.now
        let givenFileUrl = containerUrl.appendingPathComponent(.random())
        try FileManager.default.createFile(atPath: givenFileUrl.path,
                                           contents: .random(),
                                           attributes: [.creationDate: givenDate])

        // When
        let creationDate = try #require(try FileUtils.getCreationDate(url: givenFileUrl))

        // Then
        #expect(creationDate == givenDate)
    }

    @Test func `get modification date`() throws {
        // Given
        let givenDate = Date.now
        let givenFileUrl = containerUrl.appendingPathComponent(.random())
        try FileManager.default.createFile(atPath: givenFileUrl.path,
                                           contents: .random(),
                                           attributes: [.modificationDate: givenDate])

        // When
        let modificationDate = try #require(try FileUtils.getModificationDate(url: givenFileUrl))

        // Then
        #expect(modificationDate == givenDate)
    }

    @Test func `check obsolescences`() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // Then
        #expect(!FileUtils.isObsolete(url: fileUrl,
                                      currentDate: .now,
                                      thresholdInDays: 3))
        #expect(!FileUtils.isObsolete(url: fileUrl,
                                      currentDate: .now.adding(component: .day, value: 1),
                                      thresholdInDays: 3))
        #expect(!FileUtils.isObsolete(url: fileUrl,
                                      currentDate: .now.adding(component: .day, value: 2),
                                      thresholdInDays: 3))
        #expect(FileUtils.isObsolete(url: fileUrl,
                                     currentDate: .now.adding(component: .day, value: 3),
                                     thresholdInDays: 3))
    }

    @Test func `get valid data`() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: fileUrl, isObsolete: false)

        // Then
        #expect(data == givenData)
        #expect(FileManager.default.fileExists(atPath: fileUrl.path), "File still exists")
    }

    @Test func `get obsolete data`() throws {
        // Given
        let givenFileName = String.random()
        let givenData = try Data.random()
        let fileUrl = try FileUtils.createOrOverwrite(data: givenData,
                                                      fileName: givenFileName,
                                                      containerUrl: containerUrl)

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: fileUrl, isObsolete: true)

        // Then
        #expect(data == nil)
        #expect(!FileManager.default.fileExists(atPath: fileUrl.path), "File is removed")
    }

    @Test func `get data of non existing file`() throws {
        // Given
        let givenUrl = containerUrl.appendingPathComponent(.random())

        // When
        let data = try FileUtils.getDataRemovingIfObsolete(url: givenUrl, isObsolete: false)

        // Then
        #expect(data == nil)
    }

    @Test func `process file block by block`() async throws {
        // Given
        let url = FileManager.default.temporaryDirectory.appending(component: "test")
        FileManager.default.createFile(atPath: url.path(),
                                       contents: Data([4, 7, 3, 8, 5]))

        // When
        var indexes = [Int]()
        var datas = [Data]()

        try await FileUtils.processBlockByBlock(url,
                                                blockSizeInBytes: 1,
                                                process: { block in
            indexes.append(block.index)
            datas.append(block.value)
        })

        // Then
        #expect(indexes == [0, 1, 2, 3, 4])
        #expect(datas == [Data([4]), Data([7]), Data([3]), Data([8]), Data([5])])
    }
}
