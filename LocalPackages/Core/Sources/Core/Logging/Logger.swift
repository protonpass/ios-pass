//
// Logger.swift
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

import Entities
import Foundation

public enum LoggerConsolePrintOption: Sendable {
    /// Never print to console
    case never
    /// Print when in DEBUG mode
    case debug
    /// Print when value of boolean is `true`
    case conditioned(Bool)
}

public struct Logger: Sendable {
    let subsystem: String
    let category: String
    public let manager: any LogManagerProtocol
    let consolePrintOption: LoggerConsolePrintOption

    public init(manager: any LogManagerProtocol,
                subsystem: String = Bundle.main.bundleIdentifier ?? "",
                category: String = "\(Self.self)",
                consolePrintOption: LoggerConsolePrintOption = .debug) {
        self.subsystem = subsystem
        self.category = category
        self.manager = manager
        self.consolePrintOption = consolePrintOption
    }
}

// MARK: - Public APIs

public extension Logger {
    @discardableResult
    func error(_ message: String,
               timestamp: TimeInterval = Date().timeIntervalSince1970,
               file: String = #file,
               function: String = #function,
               line: UInt = #line,
               column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: message,
                                  timestamp: timestamp,
                                  level: .error,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }

    @discardableResult
    func error(_ error: some Error,
               timestamp: TimeInterval = Date().timeIntervalSince1970,
               file: String = #file,
               function: String = #function,
               line: UInt = #line,
               column: UInt = #column) -> LogEntry {
        self.error(error.localizedDebugDescription,
                   timestamp: timestamp,
                   file: file,
                   function: function,
                   line: line,
                   column: column)
    }

    @discardableResult
    func error(message: String,
               error: any Error,
               timestamp: TimeInterval = Date().timeIntervalSince1970,
               file: String = #file,
               function: String = #function,
               line: UInt = #line,
               column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: "\(message) \(String(describing: error))",
                                  timestamp: timestamp,
                                  level: .error,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }

    @discardableResult
    func warning(_ message: String,
                 timestamp: TimeInterval = Date().timeIntervalSince1970,
                 file: String = #file,
                 function: String = #function,
                 line: UInt = #line,
                 column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: message,
                                  timestamp: timestamp,
                                  level: .warning,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }

    @discardableResult
    func info(_ message: String,
              timestamp: TimeInterval = Date().timeIntervalSince1970,
              file: String = #file,
              function: String = #function,
              line: UInt = #line,
              column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: message,
                                  timestamp: timestamp,
                                  level: .info,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }

    @discardableResult
    func debug(_ message: String,
               timestamp: TimeInterval = Date().timeIntervalSince1970,
               file: String = #file,
               function: String = #function,
               line: UInt = #line,
               column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: message,
                                  timestamp: timestamp,
                                  level: .debug,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }

    @discardableResult
    func trace(_ message: String,
               timestamp: TimeInterval = Date().timeIntervalSince1970,
               file: String = #file,
               function: String = #function,
               line: UInt = #line,
               column: UInt = #column) -> LogEntry {
        let entry = generateEntry(message: message,
                                  timestamp: timestamp,
                                  level: .trace,
                                  file: file,
                                  function: function,
                                  line: line,
                                  column: column)
        log(entry: entry)
        return entry
    }
}

// MARK: - Private APIs

private extension Logger {
    // swiftlint:disable:next function_parameter_count
    func generateEntry(message: String,
                       timestamp: TimeInterval,
                       level: LogLevel,
                       file: String,
                       function: String,
                       line: UInt,
                       column: UInt) -> LogEntry {
        // Make "path/to/folder/MyClass.swift" becomes "MyClass"
        let formattedFile = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        return .init(timestamp: timestamp,
                     subsystem: subsystem,
                     category: category,
                     level: level,
                     message: message,
                     file: formattedFile,
                     function: function,
                     line: line,
                     column: column)
    }

    func log(entry: LogEntry) {
        Task {
            await manager.log(entry: entry)
            printToConsoleIfNecessary(entry: entry)
        }
    }

    func printToConsoleIfNecessary(entry: LogEntry) {
        let printToConsole: () -> Void = {
            print(LogFormatter.default.format(entry: entry))
        }
        switch consolePrintOption {
        case .never:
            return
        case .debug:
            #if DEBUG
            if ProcessInfo.processInfo.environment["me.proton.pass.LogDebug"] != "1" {
                printToConsole()
            }
            #endif
        case let .conditioned(condition):
            if condition {
                printToConsole()
            }
        }
    }
}
