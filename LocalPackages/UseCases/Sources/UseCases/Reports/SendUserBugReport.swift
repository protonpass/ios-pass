//
// SendUserBugReport.swift
// Proton Pass - Created on 03/07/2023.
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
import Entities
import Foundation

/**
 The SendUserBugReportUseCase protocol defines the contract for a use case that handles sending user bug reports.
 It inherits from the `Sendable protocol, which allows the use case to be executed asynchronously.
 */
public protocol SendUserBugReportUseCase: Sendable {
    /**
     Executes the use case to send a bug report with the specified title and description.

     - Parameters:
       - title: The title of the bug report.
       - description: The description of the bug report.

     - Returns: A `Bool` value indicating whether the bug report was sent successfully or not.

     - Throws: An error if an issue occurs while sending the bug report.
     */
    func execute(with title: String,
                 and description: String,
                 shouldSendLogs: Bool,
                 otherLogContent: [String: URL]?) async throws -> Bool
}

public extension SendUserBugReportUseCase {
    /**
     Convenience method that allows the use case to be invoked as a function, simplifying its usage.

     - Parameters:
       - title: The title of the bug report.
       - description: The description of the bug report.

     - Returns: A `Bool` value indicating whether the bug report was sent successfully or not.

     - Throws: An error if an issue occurs while sending the bug report.
     */
    func callAsFunction(with title: String,
                        and description: String,
                        shouldSendLogs: Bool,
                        otherLogContent: [String: URL]? = nil) async throws -> Bool {
        try await execute(with: title,
                          and: description,
                          shouldSendLogs: shouldSendLogs,
                          otherLogContent: otherLogContent)
    }
}

public final class SendUserBugReport: SendUserBugReportUseCase {
    private let reportRepository: any ReportRepositoryProtocol
    private let extractLogsToFile: any ExtractLogsToFileUseCase
    private let getLogEntries: any GetLogEntriesUseCase

    /**
     Initializes a new instance of `SendUserBugReport` with the specified dependencies.

     - Parameters:
       - reportRepository: The repository responsible for sending the bug report.
       - extractLogsToFile: The use case responsible for extracting logs to a file.
       - getLogEntries: The use case responsible for retrieving log entries.
     */
    public init(reportRepository: any ReportRepositoryProtocol,
                extractLogsToFile: any ExtractLogsToFileUseCase,
                getLogEntries: any GetLogEntriesUseCase) {
        self.reportRepository = reportRepository
        self.extractLogsToFile = extractLogsToFile
        self.getLogEntries = getLogEntries
    }

    /**
     Executes the use case to send a bug report with the specified title and description.

     - Parameters:
       - title: The title of the bug report.
       - description: The description of the bug report.

     - Returns: A `Bool` value indicating whether the bug report was sent successfully or not.

     - Throws: An error if an issue occurs while sending the bug report.
     */
    public func execute(with title: String,
                        and description: String,
                        shouldSendLogs: Bool,
                        otherLogContent: [String: URL]? = nil) async throws -> Bool {
        var logs = [String: URL]()

        if shouldSendLogs {
            if let hostAppEntries = await createLogsFile(for: .hostApp) {
                logs[ReportFileKey.hostApp.rawValue] = hostAppEntries
            }
            if let autofillEntries = await createLogsFile(for: .autoFillExtension) {
                logs[ReportFileKey.autofill.rawValue] = autofillEntries
            }
        }
        if let otherLogContent {
            logs = logs.merging(otherLogContent) { _, new in new }
        }
        return try await reportRepository.sendBug(with: title, and: description, optional: logs)
    }
}

private extension SendUserBugReport {
    func createLogsFile(for module: PassModule) async -> URL? {
        guard let entries = try? await getLogEntries(for: module),
              let logFileUrl = try? await extractLogsToFile(for: entries,
                                                            in: module.exportLogFileName) else {
            return nil
        }
        return logFileUrl
    }
}
