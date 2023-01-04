//
// LogFormatter.swift
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

public enum LogFormat {
    case txt
    case html(LogFormatStyle)
}

public struct LogFormatStyle {
    public typealias HexColor = String

    /// Colors in hex format with `#` prefix for `subsystem` strings.
    /// For example: ["me.proton.pass.ios": "#123456", "me.proton.pass.ios.autofill": "#ABCDEF"]
    let subsystemColors: [String: HexColor]

    /// Same as `subsystemColors` but for `category` strings.
    let categoryColors: [String: HexColor]

    public init(subsystemColors: [String: HexColor],
                categoryColors: [String: HexColor]) {
        self.subsystemColors = subsystemColors
        self.categoryColors = categoryColors
    }
}

public struct LogFormatOptions: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// `🔴 ERROR` instead of `ERROR`
    static let logLevelEmoji = LogFormatOptions(rawValue: 1 << 0)
    /// Include `subsystem` field or not
    static let subsystem = LogFormatOptions(rawValue: 1 << 1)
    /// Include `category` field or not
    static let category = LogFormatOptions(rawValue: 1 << 2)
    /// Include `file`, `function`, `line`, `column` fields or not
    static let fileFunctionLineColumn = LogFormatOptions(rawValue: 1 << 3)

    // Predefined options
    /// Include everything
    public static let verbose: LogFormatOptions = [.logLevelEmoji,
                                                   .subsystem,
                                                   .category,
                                                   .fileFunctionLineColumn]

    /// Only include `subsystem` & `category`
    public static let standard: LogFormatOptions = [.subsystem, .category]
}

public let kDefaultLogDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    return dateFormatter
}()

public final class LogFormatter {
    let format: LogFormat
    let dateFormatter: DateFormatter
    let options: LogFormatOptions

    public init(format: LogFormat,
                dateFormatter: DateFormatter = kDefaultLogDateFormatter,
                options: LogFormatOptions = .verbose) {
        self.format = format
        self.dateFormatter = dateFormatter
        self.options = options
    }

    /// `txt`  format, `yyyy-MM-dd'T'HH:mm:ssZ` as date format & `verbose` options
    public static var `default`: LogFormatter {
        .init(format: .txt)
    }
}

// MARK: - Public APIs
public extension LogFormatter {
    func format(entries: [LogEntry]) async -> String {
        await Task.detached(priority: .userInitiated) {
            let formattedEntries = entries.map(self.format(entry:))
            switch self.format {
            case .txt:
                return formattedEntries.joined(separator: "\n")
            case .html:
                return """
<!doctype html>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1">
<html>
    <head>
        <style>
            body {
                padding-left: 12px;
                padding-right: 12px;
                font-family: -apple-system;
                font-size: 17px;
            }
        </style>
    </head>
    <body>
\(formattedEntries.joined(separator: "<br/>"))
    </body>
</html>
"""
            }
        }.value
    }
}

// MARK: - Internal APIs
extension LogFormatter {
    func format(entry: LogEntry) -> String {
        switch format {
        case .txt:
            return txtFormat(entry: entry)
        case .html(let style):
            return htmlFormat(entry: entry, style: style)
        }
    }

    func txtFormat(entry: LogEntry) -> String {
        // Always include date
        let date = Date(timeIntervalSince1970: entry.timestamp)
        let dateString = dateFormatter.string(from: date)

        // Log level
        let logLevelString: String
        if options.contains(.logLevelEmoji) {
            logLevelString = entry.level.descriptionWithEmoji
        } else {
            logLevelString = entry.level.rawValue
        }

        // Subsystem
        var subsystemString: String?
        if options.contains(.subsystem) {
            subsystemString = entry.subsystem
        }

        // Category
        var categoryString: String?
        if options.contains(.category) {
            categoryString = entry.category
        }

        // File, function, line & column
        var fileFunctionLineColumnString: String?
        if options.contains(.fileFunctionLineColumn) {
            fileFunctionLineColumnString = "\(entry.file).\(entry.function):\(entry.line):\(entry.column)"
        }

        // Get except message because we want to concatenate message with a different separator
        let strings = [dateString,
                       logLevelString,
                       subsystemString,
                       categoryString,
                       fileFunctionLineColumnString].compactMap { $0 }

        let everythingExceptMessage = strings.joined(separator: " | ")

        return "\(everythingExceptMessage) - \(entry.message)"
    }

    func htmlFormat(entry: LogEntry, style: LogFormatStyle) -> String {
        // Always include date
        let date = Date(timeIntervalSince1970: entry.timestamp)
        let dateString = dateFormatter.string(from: date)

        // Log level
        let logLevelString: String
        if options.contains(.logLevelEmoji) {
            logLevelString = entry.level.descriptionWithEmoji
        } else {
            logLevelString = entry.level.rawValue
        }

        // Subsystem
        var subsystemString: String?
        if options.contains(.subsystem) {
            if let color = style.subsystemColors[entry.subsystem] {
                subsystemString = "<span style=\"color:\(color)\">\(entry.subsystem)</span>"
            } else {
                subsystemString = entry.subsystem
            }
        }

        // Category
        var categoryString: String?
        if options.contains(.category) {
            if let color = style.categoryColors[entry.category] {
                categoryString = "<span style=\"color:\(color)\">\(entry.category)</span>"
            } else {
                categoryString = entry.category
            }
        }

        // File, function, line & column
        var fileFunctionLineColumnString: String?
        if options.contains(.fileFunctionLineColumn) {
            fileFunctionLineColumnString = "\(entry.file).\(entry.function):\(entry.line):\(entry.column)"
        }

        // Get except message because we want to concatenate message with a different separator
        let strings = [dateString,
                       logLevelString,
                       subsystemString,
                       categoryString,
                       fileFunctionLineColumnString].compactMap { $0 }

        let everythingExceptMessage = strings.joined(separator: " | ")

        return "\(everythingExceptMessage) - \(entry.message)"
    }
}
