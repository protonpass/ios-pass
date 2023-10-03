//
// LogLevel.swift
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

public enum LogLevel: String, Codable, CaseIterable, Sendable {
    case fatal = "FATAL"
    case error = "ERROR"
    case warning = "WARNING"
    case info = "INFO"
    case debug = "DEBUG"
    case trace = "TRACE"

    private var emoji: String {
        switch self {
        case .error, .fatal: "🔴"
        case .warning: "🟡"
        case .info: "🔵"
        case .trace: "⚫"
        case .debug: "🟣"
        }
    }

    public var descriptionWithEmoji: String {
        "\(emoji) \(rawValue)"
    }
}
