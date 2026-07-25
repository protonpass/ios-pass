//
// LogEntry.swift
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

import Foundation
import os

public struct LogEntry: Codable, Sendable {
    public let timestamp: TimeInterval
    public let subsystem: String
    public let category: String
    public let level: LogLevel
    public let message: String
    public let file: String
    public let function: String
    public let line: UInt
    public let column: UInt

    /// Process-monotonic creation order, minted by the initialiser's default argument.
    ///
    /// `Logger.log(entry:)` dispatches every entry in its own unstructured `Task`, so entries
    /// reach `LogManager` in arbitrary order — arrival order cannot break a timestamp tie, it is
    /// the thing that got scrambled. This records the order the entries were actually created in.
    ///
    /// `Optional` on purpose: the synthesised `Codable` then uses `decodeIfPresent`, so log files
    /// written before this field existed still decode instead of vanishing from the log viewer.
    ///
    /// Resets with the process while the log file outlives it, so this is only meaningful *within*
    /// one timestamp: sort on `(timestamp, sequence)`, never on `sequence` alone.
    public let sequence: UInt64?

    public init(timestamp: TimeInterval,
                subsystem: String,
                category: String,
                level: LogLevel,
                message: String,
                file: String,
                function: String,
                line: UInt,
                column: UInt,
                sequence: UInt64? = LogEntry.nextSequence()) {
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.category = category
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.column = column
        self.sequence = sequence
    }
}

public extension LogEntry {
    /// The default for `sequence`. `public` because default argument expressions are inlined at
    /// the call site; call it directly only when reconstructing an entry with a known order.
    static func nextSequence() -> UInt64 {
        sequencer.withLock { count in
            count += 1
            return count
        }
    }
}

extension LogEntry {
    /// One counter per process. Modules log to separate files (`PassModule.logFileName`), so a
    /// per-process counter is a total order over everything that lands in any one file.
    private static let sequencer = OSAllocatedUnfairLock(initialState: UInt64(0))

    /// Chronological by emission: timestamps order across process launches, `sequence` breaks the
    /// ties within one launch. Entries predating `sequence` compare as `0` and keep their relative
    /// order, which is the order they already had.
    static func isBefore(_ lhs: LogEntry, _ rhs: LogEntry) -> Bool {
        (lhs.timestamp, lhs.sequence ?? 0) < (rhs.timestamp, rhs.sequence ?? 0)
    }
}
