//
// ExtractLogsToFileTests.swift
// Proton Pass - Created on 03/07/2023.
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

import FactoryKit
import Foundation
import XCTest
import UseCases
@testable import Proton_Pass

class ExtractLogsToFileTests: XCTestCase {
    var sut: ExtractLogsToFileUseCase!
    var path: String?
    let testFileName = "TestFileLogs.log"
    
    override func setUp() {
        super.setUp()
        sut = ExtractLogsToFile(logFormatter: SharedToolingContainer.shared.logFormatter())
    }
    
    override func tearDown() {
        super.setUp()
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(testFileName)
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    func testWrittingLogsToFile() async throws {
        let entry = LogEntryFactory.createMock()
        let url = try await sut(for: [entry], in: testFileName)
        guard let url, FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("Should have created a file with the log entry")
            return
        }
        
        XCTAssertEqual(url.lastPathComponent, "TestFileLogs.log")
    }
}
