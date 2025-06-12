// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

 // Check if the protocol inherits from Actor
public actor LogManagerProtocolMock: LogManagerProtocol {

    public init() {}

    // MARK: - shouldLog
    public var invokedShouldLogSetter = false
    public var invokedShouldLogSetterCount = 0
    public var invokedShouldLog: Bool?
    public var invokedShouldLogList = [Bool?]()
    public var invokedShouldLogGetter = false
    public var invokedShouldLogGetterCount = 0
    public var stubbedShouldLog: Bool!
    public var shouldLog: Bool {
        set {
            invokedShouldLogSetter = true
            invokedShouldLogSetterCount += 1
            invokedShouldLog = newValue
            invokedShouldLogList.append(newValue)
        } get {
            invokedShouldLogGetter = true
            invokedShouldLogGetterCount += 1
            return stubbedShouldLog
        }
    }
    // MARK: - log
    public var closureLog: () -> () = {}
    public var invokedLogfunction = false
    public var invokedLogCount = 0
    public var invokedLogParameters: (entry: LogEntry, Void)?
    public var invokedLogParametersList = [(entry: LogEntry, Void)]()

    public func log(entry: LogEntry) {
        invokedLogfunction = true
        invokedLogCount += 1
        invokedLogParameters = (entry, ())
        invokedLogParametersList.append((entry, ()))
        closureLog()
    }
    // MARK: - getLogEntries
    public var getLogEntriesThrowableError2: Error?
    public var closureGetLogEntries: () -> () = {}
    public var invokedGetLogEntriesfunction = false
    public var invokedGetLogEntriesCount = 0
    public var stubbedGetLogEntriesResult: [LogEntry]!

    public func getLogEntries() async throws -> [LogEntry] {
        invokedGetLogEntriesfunction = true
        invokedGetLogEntriesCount += 1
        if let error = getLogEntriesThrowableError2 {
            throw error
        }
        closureGetLogEntries()
        return stubbedGetLogEntriesResult
    }
    // MARK: - removeAllLogs
    public var closureRemoveAllLogs: () -> () = {}
    public var invokedRemoveAllLogsfunction = false
    public var invokedRemoveAllLogsCount = 0

    public func removeAllLogs() {
        invokedRemoveAllLogsfunction = true
        invokedRemoveAllLogsCount += 1
        closureRemoveAllLogs()
    }
    // MARK: - saveAllLogs
    public var closureSaveAllLogs: () -> () = {}
    public var invokedSaveAllLogsfunction = false
    public var invokedSaveAllLogsCount = 0

    public func saveAllLogs() {
        invokedSaveAllLogsfunction = true
        invokedSaveAllLogsCount += 1
        closureSaveAllLogs()
    }
    // MARK: - toggleLogging
    public var closureToggleLogging: () -> () = {}
    public var invokedToggleLoggingfunction = false
    public var invokedToggleLoggingCount = 0
    public var invokedToggleLoggingParameters: (shouldLog: Bool, Void)?
    public var invokedToggleLoggingParametersList = [(shouldLog: Bool, Void)]()

    public func toggleLogging(shouldLog: Bool) {
        invokedToggleLoggingfunction = true
        invokedToggleLoggingCount += 1
        invokedToggleLoggingParameters = (shouldLog, ())
        invokedToggleLoggingParametersList.append((shouldLog, ()))
        closureToggleLogging()
    }
}
