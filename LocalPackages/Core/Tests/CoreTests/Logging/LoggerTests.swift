//
// LoggerTests.swift
// Proton Pass - Created on 04/01/2023.
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

final class LoggerTests: XCTestCase {
    private static let fileName = "LoggerTests"
    private static let subsystem = "me.proton.logger"
    private static let category = "logger_tests"
    var sut: Logger!

    override func setUp() {
        super.setUp()
        // swiftlint:disable:next force_unwrapping
        let url = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        sut =
            .init(manager: LogManager(url: url, fileName: "test.log",
                                      config: LogManagerConfig(maxLogLines: 2_000)),
                  subsystem: Self.subsystem,
                  category: Self.category)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGenerateFatalLogEntry() {
        let message = "Something fatal happened"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.fatal(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .fatal)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateFatalLogEntry()")
        XCTAssertEqual(entry.line, 49)
        XCTAssertEqual(entry.column, 30)
    }

    func testGenerateErrorLogEntry() {
        let message = "Error occured"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.error(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .error)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateErrorLogEntry()")
        XCTAssertEqual(entry.line, 64)
        XCTAssertEqual(entry.column, 30)
    }

    func testGenerateWarningLogEntry() {
        let message = "Low memory ⚠️"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.warning(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .warning)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateWarningLogEntry()")
        XCTAssertEqual(entry.line, 79)
        XCTAssertEqual(entry.column, 32)
    }

    func testGenerateInfoLogEntry() {
        let message = "ℹ️ Request sent"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.info(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .info)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateInfoLogEntry()")
        XCTAssertEqual(entry.line, 94)
        XCTAssertEqual(entry.column, 29)
    }

    func testGenerateDebugLogEntry() {
        let message = "Some debug message"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.debug(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .debug)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateDebugLogEntry()")
        XCTAssertEqual(entry.line, 109)
        XCTAssertEqual(entry.column, 30)
    }

    func testGenerateTraceLogEntry() {
        let message = "Some trace message"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.trace(message, timestamp: timestamp)
        XCTAssertEqual(entry.timestamp, timestamp)
        XCTAssertEqual(entry.subsystem, Self.subsystem)
        XCTAssertEqual(entry.category, Self.category)
        XCTAssertEqual(entry.level, .trace)
        XCTAssertEqual(entry.message, message)
        XCTAssertEqual(entry.file, Self.fileName)
        XCTAssertEqual(entry.function, "testGenerateTraceLogEntry()")
        XCTAssertEqual(entry.line, 124)
        XCTAssertEqual(entry.column, 30)
    }
}
