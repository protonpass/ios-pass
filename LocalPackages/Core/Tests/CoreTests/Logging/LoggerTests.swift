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
import Foundation
import Testing

@Suite(.tags(.logging))
struct LoggerTests {
    private static let fileName = "LoggerTests"
    private static let subsystem = "me.proton.logger"
    private static let category = "logger_tests"
    private let sut: Logger

    init() {
        sut = .init(manager: LogManager(url: FileManager.default.temporaryDirectory,
                                        fileName: "loggerTest-\(UUID().uuidString).log",
                                        config: LogManagerConfig(maxLogLines: 2_000)),
                    subsystem: Self.subsystem,
                    category: Self.category)
    }

    @Test func `error captures the call site and metadata`() {
        let message = "Error occurred"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.error(message, timestamp: timestamp)
        #expect(entry.timestamp == timestamp)
        #expect(entry.subsystem == Self.subsystem)
        #expect(entry.category == Self.category)
        #expect(entry.level == .error)
        #expect(entry.message == message)
        #expect(entry.file == Self.fileName)
        #expect(entry.function == #function)
        #expect(entry.line == 43)
        #expect(entry.column == 30)
    }

    @Test func `warning captures the call site and metadata`() {
        let message = "Low memory ⚠️"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.warning(message, timestamp: timestamp)
        #expect(entry.timestamp == timestamp)
        #expect(entry.subsystem == Self.subsystem)
        #expect(entry.category == Self.category)
        #expect(entry.level == .warning)
        #expect(entry.message == message)
        #expect(entry.file == Self.fileName)
        #expect(entry.function == #function)
        #expect(entry.line == 58)
        #expect(entry.column == 32)
    }

    @Test func `info captures the call site and metadata`() {
        let message = "ℹ️ Request sent"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.info(message, timestamp: timestamp)
        #expect(entry.timestamp == timestamp)
        #expect(entry.subsystem == Self.subsystem)
        #expect(entry.category == Self.category)
        #expect(entry.level == .info)
        #expect(entry.message == message)
        #expect(entry.file == Self.fileName)
        #expect(entry.function == #function)
        #expect(entry.line == 73)
        #expect(entry.column == 29)
    }

    @Test func `debug captures the call site and metadata`() {
        let message = "Some debug message"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.debug(message, timestamp: timestamp)
        #expect(entry.timestamp == timestamp)
        #expect(entry.subsystem == Self.subsystem)
        #expect(entry.category == Self.category)
        #expect(entry.level == .debug)
        #expect(entry.message == message)
        #expect(entry.file == Self.fileName)
        #expect(entry.function == #function)
        #expect(entry.line == 88)
        #expect(entry.column == 30)
    }

    @Test func `trace captures the call site and metadata`() {
        let message = "Some trace message"
        let timestamp = Date().timeIntervalSince1970
        let entry = sut.trace(message, timestamp: timestamp)
        #expect(entry.timestamp == timestamp)
        #expect(entry.subsystem == Self.subsystem)
        #expect(entry.category == Self.category)
        #expect(entry.level == .trace)
        #expect(entry.message == message)
        #expect(entry.file == Self.fileName)
        #expect(entry.function == #function)
        #expect(entry.line == 103)
        #expect(entry.column == 30)
    }
}
