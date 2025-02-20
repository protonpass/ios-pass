//
// ParseCsvLogins.swift
// Proton Pass - Created on 26/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public protocol ParseCsvLoginsUseCase: Sendable {
    func execute(_ csv: String) async throws -> [CsvLogin]
}

public extension ParseCsvLoginsUseCase {
    func callAsFunction(_ csv: String) async throws -> [CsvLogin] {
        try await execute(csv)
    }
}

public final class ParseCsvLogins: ParseCsvLoginsUseCase {
    private let validateEmail: any ValidateEmailUseCase

    public init(validateEmail: any ValidateEmailUseCase = ValidateEmail()) {
        self.validateEmail = validateEmail
    }

    public func execute(_ csv: String) async throws -> [CsvLogin] {
        var rows = csv.components(separatedBy: "\n")

        // Some CSV files have empty last row, so we remove it
        if rows.last?.isEmpty == true {
            _ = rows.popLast()
        }

        var results = [CsvLogin]()
        var hasNoteColumn = false
        for (index, row) in rows.enumerated() {
            if index == 0 {
                let columnNames = row.components(separatedBy: ",")
                guard columnNames.count == 4 || columnNames.count == 5 else {
                    throw PassError.csv(.invalidNumberOfColumn(columnNames.count))
                }

                try expect(columnName: "name", at: 0, for: columnNames)
                try expect(columnName: "url", at: 1, for: columnNames)
                try expect(columnName: "username", at: 2, for: columnNames)
                try expect(columnName: "password", at: 3, for: columnNames)

                hasNoteColumn = columnNames.count == 5
                if hasNoteColumn {
                    try expect(columnName: "note", at: 4, for: columnNames)
                }
            } else {
                let login = try parse(row: row, at: index, hasNoteColumn: hasNoteColumn)
                results.append(login)
            }
        }
        return results
    }
}

private extension ParseCsvLogins {
    func expect(columnName: String, at index: Int, for columns: [String]) throws {
        guard let name = columns[safeIndex: index] else {
            assertionFailure("Should never happen")
            return
        }
        if name != columnName {
            throw PassError.csv(.unexpectedColumnName(index: index,
                                                      expectation: columnName,
                                                      value: name))
        }
    }

    func parse(row: String, at index: Int, hasNoteColumn: Bool) throws -> CsvLogin {
        // When the content of the column has ',' characters or spaces
        // the content will be double quoted
        //
        // E.g:
        // name,age,city
        // "John, Doe",, "New York, USA"
        //
        // So we need to go over character by character to parse

        var columns = [String]()
        var currentColumn = ""
        var insideQuotes = false
        var skipNextQuote = false

        for char in row {
            if skipNextQuote {
                // Skip the next quote character
                currentColumn.append(char)
                skipNextQuote = false
                continue
            }

            if char == "\"" {
                insideQuotes.toggle()
                // If we close the quote, check if this is an escaped quote (i.e., "")
                if !insideQuotes, currentColumn.last == "\"" {
                    currentColumn.removeLast() // Remove the escaped quote
                    skipNextQuote = true // Set flag to skip the next quote
                }
            } else if char == ",", !insideQuotes {
                // When we reach a comma outside of quotes, we have a complete column
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                // Accumulate characters into the current column
                currentColumn.append(char)
            }
        }

        // Append the last column if there are remaining characters
        if !currentColumn.isEmpty {
            columns.append(currentColumn)
        }

        // Handle trailing commas for missing columns
        if row.last == "," {
            columns.append("")
        }

        guard hasNoteColumn ? columns.count == 5 : columns.count == 4,
              let name = columns[safeIndex: 0],
              let url = columns[safeIndex: 1],
              let emailOrUsername = columns[safeIndex: 2],
              let password = columns[safeIndex: 3] else {
            throw PassError.csv(.invalidRow(index))
        }

        let email: String
        let username: String
        if validateEmail(email: emailOrUsername) {
            email = emailOrUsername
            username = ""
        } else {
            email = ""
            username = emailOrUsername
        }

        return .init(name: name,
                     url: url,
                     email: email,
                     username: username,
                     password: password,
                     note: columns[safeIndex: 4] ?? "")
    }
}
