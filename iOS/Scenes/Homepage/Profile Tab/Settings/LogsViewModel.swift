//
// LogsViewModel.swift
// Proton Pass - Created on 31/03/2023.
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

import Core
import Entities
import Factory
import SwiftUI

@MainActor
protocol LogsViewModelDelegate: AnyObject {
    func logsViewModelWantsToShareLogs(_ url: URL)
}

@MainActor
final class LogsViewModel: DeinitPrintable, ObservableObject {
    deinit {
        print(deinitMessage)
        if let fileToDelete {
            try? FileManager.default.removeItem(at: fileToDelete)
        }
    }

    @Published private(set) var isLoading = true
    @Published private(set) var entries = [LogEntry]()
    @Published private(set) var error: Error?
    @Published private(set) var sharingLogs = false
    @Published var logLevel: LogLevel?

    var formattedEntries: [String] {
        let takenEntries: [LogEntry] = if let logLevel {
            entries.filter { $0.level == logLevel }
        } else {
            entries
        }
        return takenEntries.map(logFormatter.format(entry:))
    }

    private var fileToDelete: URL?

    private let logFormatter: LogFormatterProtocol
    let module: PassModule

    weak var delegate: LogsViewModelDelegate?

    private let getLogEntries = resolve(\UseCasesContainer.getLogEntries)
    private let extractLogsToFile = resolve(\UseCasesContainer.extractLogsToFile)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init(module: PassModule) {
        self.module = module
        logFormatter = SharedToolingContainer.shared.logFormatter()
        loadLogs()
    }

    func loadLogs() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                self.isLoading = true
                self.entries = try await self.getLogEntries(for: self.module)
            } catch {
                self.error = error
            }
        }
    }

    func shareLogs() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.sharingLogs = false }
            do {
                self.sharingLogs = true
                self.fileToDelete = try await self.extractLogsToFile(for: self.entries,
                                                                     in: self.module.exportLogFileName)
                if let fileToDelete {
                    self.delegate?.logsViewModelWantsToShareLogs(fileToDelete)
                }
            } catch {
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
