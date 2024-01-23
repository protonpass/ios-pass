//
// GetLogsEntriesTests.swift
// Proton Pass - Created on 29/06/2023.
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

import Foundation
import Core
import Entities
import UseCases
import XCTest
@testable import Proton_Pass

enum LogEntryFactory {
    static func createMock(timestamp: TimeInterval = 0,
                           subsystem: String = "",
                           category: String = "",
                           level: LogLevel = .debug,
                           message: String = "",
                           file: String = "",
                           function: String = "",
                           line: UInt = 0,
                           column: UInt = 0) -> LogEntry {
        .init(timestamp: timestamp,
              subsystem: subsystem,
              category: category,
              level: level,
              message: message,
              file: file,
              function: function,
              line: line,
              column: column)
    }
    
    static func createMockArray(count: Int,
                                timestamp: TimeInterval = 0,
                                subsystem: String = "",
                                category: String = "",
                                level: LogLevel = .debug,
                                message: String = "",
                                file: String = "",
                                function: String = "",
                                line: UInt = 0,
                                column: UInt = 0) -> [LogEntry] {
        .init(repeating: LogEntryFactory.createMock(), count: count)
    }
}

class GetLogEntriesTests: XCTestCase {
    @MainActor
    func testGettingLogsForDifferentPassLogModule() async throws {
        // Create mock dependencies
        let mainAppLogManager = LogManagerMock()
        let autofillLogManager = LogManagerMock()
        let keyboardLogManager = LogManagerMock()
        let shareLogManager = LogManagerMock()

        // Create an instance of GetLogEntries with mock dependencies
        let getLogEntries = GetLogEntries(mainAppLogManager: mainAppLogManager,
                                          autofillLogManager: autofillLogManager,
                                          keyboardLogManager: keyboardLogManager,
                                          shareLogManager: shareLogManager)

        // Set up the expected behavior for the mock dependencies
        await mainAppLogManager.log(entry: LogEntryFactory.createMock())
        await autofillLogManager.log(entry: LogEntryFactory.createMock())
        await autofillLogManager.log(entry: LogEntryFactory.createMock())
        await keyboardLogManager.log(entry: LogEntryFactory.createMock())
        await keyboardLogManager.log(entry: LogEntryFactory.createMock())
        await keyboardLogManager.log(entry: LogEntryFactory.createMock())

        // Call the execute function and await the result
        let hostAppLogEntries = try await getLogEntries.execute(for: .hostApp)
        let autoFillLogEntries = try await getLogEntries.execute(for: .autoFillExtension)
        let keyboardLogEntries = try await getLogEntries.execute(for: .keyboardExtension)

        // Assert the expected results
        XCTAssertEqual(hostAppLogEntries.count, 1)
        XCTAssertEqual(autoFillLogEntries.count, 2)
        XCTAssertEqual(keyboardLogEntries.count, 3)
    }
}
