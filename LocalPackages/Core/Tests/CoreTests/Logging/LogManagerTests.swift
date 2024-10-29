//
// LogManagerTests.swift
// Proton Pass - Created on 14/06/2023.
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

final class LogManagerTests: XCTestCase, @unchecked Sendable {
    private static let destinationFile = "logManagerTest.log"
    var sut: LogManagerProtocol!

    override func setUp() {
        super.setUp()
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        sut = LogManager(url: url,
                         fileName: LogManagerTests.destinationFile,
                         config: LogManagerConfig(maxLogLines: 10,
                                                  dumpThreshold: 5,
                                                  timerInterval: 1))
    }

    override func tearDown() {
        Task {
            await sut.removeAllLogs()
            sut = nil
        }
        super.tearDown()
    }

    func testAddLogEntryWithoutGoingAboveDump_ShouldNotSavedLocally() async throws {
        await sut.removeAllLogs()
        await sut.log(entry: LogEntryFactory.createMock())
        let newLogEntries = try await sut.getLogEntries()
        XCTAssertTrue(newLogEntries.isEmpty)
    }

    func testAddLogEntryGoingAboveDump() async throws {
        await sut.removeAllLogs()
        await LogEntryFactory.createMockArray(count: 6).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        let newLogEntries = try await sut.getLogEntries()
        XCTAssertEqual(newLogEntries.count, 5)
    }

    func testLocalLogFileDoesntGoAboveMaxEntry() async throws {
        await sut.removeAllLogs()
        await LogEntryFactory.createMockArray(count: 30).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        let newLogEntries = try await sut.getLogEntries()
        XCTAssertEqual(newLogEntries.count, 10)
    }

    func testRemoveLogEntry() async throws {
        await sut.removeAllLogs()
        await LogEntryFactory.createMockArray(count: 50).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.removeAllLogs()

        let newLogEntries = try await sut.getLogEntries()
        XCTAssertTrue(newLogEntries.isEmpty)
    }

    func testForceLogSave() async throws {
        await sut.removeAllLogs()
        await LogEntryFactory.createMockArray(count: 3).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.saveAllLogs()

        let newLogEntries = try await sut.getLogEntries()
        XCTAssertEqual(newLogEntries.count, 3)
    }

    func testLoggingLock() async throws {
        await sut.removeAllLogs()
        await sut.toggleLogging(shouldLog: false)
        await LogEntryFactory.createMockArray(count: 3).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.saveAllLogs()

        let newLogEntries = try await sut.getLogEntries()
        XCTAssertTrue(newLogEntries.isEmpty)
        await sut.toggleLogging(shouldLog: true)
    }
}
