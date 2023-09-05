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

    public init(timestamp: TimeInterval,
                subsystem: String,
                category: String,
                level: LogLevel,
                message: String,
                file: String,
                function: String,
                line: UInt,
                column: UInt) {
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.category = category
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.column = column
    }
}
