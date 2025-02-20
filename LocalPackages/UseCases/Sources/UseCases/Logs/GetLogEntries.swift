//
//
// GetLogEntries.swift
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
import Entities

/*
 The GetLogEntriesUseCase protocol defines the contract for a use case that retrieves log entries.
 It inherits from the Sendable protocol, allowing the use case to be executed asynchronously.
 */
// sourcery: AutoMockable
public protocol GetLogEntriesUseCase: Sendable {
    /**
     Executes the use case to retrieve log entries for the specified log module.

     - Parameter module: An enum case of `PassModule`, The log module for which to retrieve log entries.

     - Returns: An array of `LogEntry` objects representing the retrieved log entries.

     - Throws: An error if an issue occurs while retrieving the log entries.
     */
    func execute(for module: PassModule) async throws -> [LogEntry]
}

public extension GetLogEntriesUseCase {
    /**
     Convenience method that allows the use case to be invoked as a function, simplifying its usage.

     - Parameter module: An enum case of `PassModule`, The log module for which to retrieve log entries.

     - Returns: An array of `LogEntry` objects representing the retrieved log entries.

     - Throws: An error if an issue occurs while retrieving the log entries.
     */
    func callAsFunction(for module: PassModule) async throws -> [LogEntry] {
        try await execute(for: module)
    }
}

public final class GetLogEntries: GetLogEntriesUseCase {
    private let mainAppLogManager: any LogManagerProtocol
    private let autofillLogManager: any LogManagerProtocol
    private let shareLogManager: any LogManagerProtocol
    private let actionLogManager: any LogManagerProtocol

    /**
     Initializes a new instance of `GetLogEntries` with the specified log managers.

     - Parameters:
       - mainAppLogManager: The log manager responsible for retrieving log entries for the main app.
       - autofillLogManager: The log manager responsible for retrieving log entries for the autofill extension.
     */
    public init(mainAppLogManager: any LogManagerProtocol,
                autofillLogManager: any LogManagerProtocol,
                shareLogManager: any LogManagerProtocol,
                actionLogManager: any LogManagerProtocol) {
        self.mainAppLogManager = mainAppLogManager
        self.autofillLogManager = autofillLogManager
        self.shareLogManager = shareLogManager
        self.actionLogManager = actionLogManager
    }

    /**
     Executes the use case to retrieve log entries for the specified log module.

     - Parameter module: The log module for which to retrieve log entries.

     - Returns: An array of `LogEntry` objects representing the retrieved log entries.

     - Throws: An error if an issue occurs while retrieving the log entries.
     */
    public func execute(for module: PassModule) async throws -> [LogEntry] {
        switch module {
        case .hostApp:
            try await mainAppLogManager.getLogEntries()
        case .autoFillExtension:
            try await autofillLogManager.getLogEntries()
        case .shareExtension:
            try await shareLogManager.getLogEntries()
        case .actionExtension:
            try await actionLogManager.getLogEntries()
        }
    }
}
