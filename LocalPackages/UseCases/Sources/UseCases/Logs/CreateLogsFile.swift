//
// CreateLogsFile.swift
// Proton Pass - Created on 26/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Foundation

public protocol CreateLogsFileUseCase: Sendable {
    func execute(for module: PassModule) async throws -> URL?
}

public extension CreateLogsFileUseCase {
    func callAsFunction(for module: PassModule) async throws -> URL? {
        try await execute(for: module)
    }
}

public final class CreateLogsFile: CreateLogsFileUseCase {
    private let extractLogsToFile: any ExtractLogsToFileUseCase
    private let getLogEntries: any GetLogEntriesUseCase

    public init(extractLogsToFile: any ExtractLogsToFileUseCase,
                getLogEntries: any GetLogEntriesUseCase) {
        self.extractLogsToFile = extractLogsToFile
        self.getLogEntries = getLogEntries
    }

    public func execute(for module: PassModule) async throws -> URL? {
        let entries = try await getLogEntries(for: module)
        return try await extractLogsToFile(for: entries, in: module.exportLogFileName)
    }
}
