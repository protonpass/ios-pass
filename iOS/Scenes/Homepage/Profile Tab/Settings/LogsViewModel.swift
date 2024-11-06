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
        if let fileToDelete {
            try? FileManager.default.removeItem(at: fileToDelete)
        }
        print(deinitMessage)
    }

    @Published private(set) var isLoading = true
    @Published private(set) var entries = [LogEntry]()
    @Published private(set) var error: (any Error)?
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

    private let logFormatter: any LogFormatterProtocol
    let module: PassModule

    weak var delegate: (any LogsViewModelDelegate)?

    private let getLogEntries = resolve(\UseCasesContainer.getLogEntries)
    private let extractLogsToFile = resolve(\UseCasesContainer.extractLogsToFile)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init(module: PassModule) {
        self.module = module
        logFormatter = SharedToolingContainer.shared.logFormatter()
        loadLogs()
    }

    func loadLogs() {
        Task { [weak self] in
            guard let self else { return }
            defer { self.isLoading = false }
            do {
                isLoading = true
                entries = try await getLogEntries(for: module)
            } catch {
                self.error = error
            }
        }
    }

    func shareLogs() {
        Task { [weak self] in
            guard let self else { return }
            defer { self.sharingLogs = false }
            do {
                sharingLogs = true
                fileToDelete = try await extractLogsToFile(for: entries,
                                                           in: module.exportLogFileName)
                if let fileToDelete {
                    delegate?.logsViewModelWantsToShareLogs(fileToDelete)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
