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

// sourcery: AutoMockable
protocol GetLogEntriesUseCase: Sendable {
    func execute(for logModule: PassLogModule) async throws -> [LogEntry]
}

extension GetLogEntriesUseCase {
    func callAsFunction(for logModule: PassLogModule) async throws -> [LogEntry] {
        try await execute(for: logModule)
    }
}

final class GetLogEntries: GetLogEntriesUseCase {
    private let mainAppLogManager: LogManagerProtocol
    private let autofillLogManager: LogManagerProtocol
    private let keyboardLogManager: LogManagerProtocol

    init(mainAppLogManager: LogManagerProtocol,
         autofillLogManager: LogManagerProtocol,
         keyboardLogManager: LogManagerProtocol) {
        self.mainAppLogManager = mainAppLogManager
        self.autofillLogManager = autofillLogManager
        self.keyboardLogManager = keyboardLogManager
    }

    func execute(for logModule: PassLogModule) async throws -> [LogEntry] {
        switch logModule {
        case .hostApp:
            return try await mainAppLogManager.getLogEntries()
        case .autoFillExtension:
            return try await autofillLogManager.getLogEntries()
        case .keyboardExtension:
            return try await keyboardLogManager.getLogEntries()
        }
    }
}
