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

@_spi(Test)
@testable import Core
import CoreMocks
import Foundation
import Testing

@Suite
struct LogManagerTests {
    private let sut: LogManagerProtocol

    init() {
        let directory = FileManager.default.temporaryDirectory
        sut = LogManager(url: directory,
                         fileName: "logManagerTest-\(UUID().uuidString).log",
                         config: LogManagerConfig(maxLogLines: 10,
                                                  dumpThreshold: 5,
                                                  timerInterval: 1))
    }

    @Test(arguments: [(entryCount: 1, expectedPersisted: 0),
                      (entryCount: 6, expectedPersisted: 5)])
    func `entries are only persisted once the dump threshold is crossed`(entryCount: Int,
                                                                         expectedPersisted: Int) async throws {
        await LogEntryFactory.createMockArray(count: entryCount).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        let entries = try await sut.getLogEntriesWithoutSave()
        #expect(entries.count == expectedPersisted)
    }
    
    @Test(arguments: [(entryCount: 1, expectedPersisted: 1),
                      (entryCount: 6, expectedPersisted: 6)])
    func `entries are only persisted if they are fetched without save`(entryCount: Int,
                                                                         expectedPersisted: Int) async throws {
        await LogEntryFactory.createMockArray(count: entryCount).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        let entries = try await sut.getLogEntries()
        #expect(entries.count == expectedPersisted)
    }

    @Test
    func `local log file is capped at maxLogLines`() async throws {
        await LogEntryFactory.createMockArray(count: 30).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        let entries = try await sut.getLogEntries()
        #expect(entries.count == 10)
    }

    @Test
    func `removeAllLogs clears persisted entries`() async throws {
        await LogEntryFactory.createMockArray(count: 50).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.removeAllLogs()

        let entries = try await sut.getLogEntries()
        #expect(entries.isEmpty)
    }

    @Test
    func `saveAllLogs persists entries below the dump threshold`() async throws {
        await LogEntryFactory.createMockArray(count: 3).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.saveAllLogs()

        let entries = try await sut.getLogEntries()
        #expect(entries.count == 3)
    }

    @Test
    func `entries logged while logging is disabled are dropped`() async throws {
        await sut.toggleLogging(shouldLog: false)
        await LogEntryFactory.createMockArray(count: 3).asyncForEach { entry in
            await sut.log(entry: entry)
        }
        await sut.saveAllLogs()

        let entries = try await sut.getLogEntries()
        #expect(entries.isEmpty)
    }
}
