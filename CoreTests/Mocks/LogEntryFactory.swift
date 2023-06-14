//
// LogEntryFactory.swift
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

import Foundation
@testable import Core

struct LogEntryFactory {
    static func createMock(timestamp: TimeInterval = 0,
                           subsystem: String = "",
                           category: String = "",
                           level: LogLevel = .debug,
                           message: String = "",
                           file: String = "",
                           function: String = "",
                           line: UInt = 0,
                           column: UInt = 0) -> LogEntry {
        return LogEntry(timestamp: timestamp,
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
        var logEntries: [LogEntry] = []
        
        for _ in 0..<count {
            let logEntry = createMock(timestamp: timestamp,
                                      subsystem: subsystem,
                                      category: category,
                                      level: level,
                                      message: message,
                                      file: file,
                                      function: function,
                                      line: line,
                                      column: column)
            logEntries.append(logEntry)
        }
        
        return logEntries
    }
}
