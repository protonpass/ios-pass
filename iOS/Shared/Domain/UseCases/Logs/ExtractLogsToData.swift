//
// ExtractLogsToData.swift
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

import Client
import Core
import Foundation

/**
 The ExtractLogsToDataUseCase protocol defines the contract for a use case that handles extracting log entries to Data.
 It inherits from the Sendable protocol, allowing the use case to be executed asynchronously.
 */
protocol ExtractLogsToDataUseCase: Sendable {
    /**
     Executes the use case to extract the specified log entries to `Data`.

     - Parameter logs: An optional array of `LogEntry` objects representing the log entries to be extracted. If `nil`, no extraction will occur.

     - Returns: An optional `Data` object containing the extracted log entries if the extraction was successful, otherwise `nil`.

     - Throws: An error if an issue occurs during the log extraction process.
     */
    func execute(for logs: [LogEntry]?) async throws -> Data?
}

extension ExtractLogsToDataUseCase {
    /**
     Convenience method that allows the use case to be invoked as a function, simplifying its usage.

     - Parameter logs: An optional array of `LogEntry` objects representing the log entries to be extracted. If `nil`, no extraction will occur.

     - Returns: An optional `Data` object containing the extracted log entries if the extraction was successful, otherwise `nil`.

     - Throws: An error if an issue occurs during the log extraction process.
     */
    func callAsFunction(for logs: [LogEntry]?) async throws -> Data? {
        try await execute(for: logs)
    }
}

/**
 The ExtractLogsToData class is an implementation of the ExtractLogsToDataUseCase protocol.
 It provides functionality for extracting log entries to Data.
 */
final class ExtractLogsToData: ExtractLogsToDataUseCase {
    private let logFormatter: LogFormatterProtocol

    init(logFormatter: LogFormatterProtocol) {
        self.logFormatter = logFormatter
    }

    /**
     Executes the use case to extract the specified log entries to `Data`.

     - Parameter logs: An optional array of `LogEntry` objects representing the log entries to be extracted. If `nil`, no extraction will occur.

     - Returns: An optional `Data` object containing the extracted log entries if the extraction was successful, otherwise `nil`.

     - Throws: An error if an issue occurs during the log extraction process.
     */
    func execute(for logs: [LogEntry]?) async throws -> Data? {
        guard let logs else {
            return nil
        }
        return await logFormatter.format(entries: logs).toBase8EncodedData
    }
}
