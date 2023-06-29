//
//
// ExtractLogsToFile.swift
// Proton Pass - Created on 29/06/2023.
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
//

import Core
import Foundation

protocol ExtractLogsToFileUseCase: Sendable {
    func execute(for entries: [LogEntry]?, in fileName: String) async throws -> URL?
}

extension ExtractLogsToFileUseCase {
    func callAsFunction(for entries: [LogEntry]?, in fileName: String) async throws -> URL? {
        try await execute(for: entries, in: fileName)
    }
}

final class ExtractLogsToFile: ExtractLogsToFileUseCase {
    private let logFormatter: LogFormatterProtocol

    init(logFormatter: LogFormatterProtocol) {
        self.logFormatter = logFormatter
    }

    func execute(for entries: [LogEntry]?, in fileName: String) async throws -> URL? {
        guard let entries else {
            return nil
        }

        let file = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let log = await logFormatter.format(entries: entries)
        try log.write(to: file, atomically: true, encoding: .utf8)
        return file
    }
}
