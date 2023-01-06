//
// DeviceLogsViewModel.swift
// Proton Pass - Created on 02/01/2023.
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
import ProtonCore_Log
import SwiftUI

protocol DeviceLogsViewModelDelegate: AnyObject {
    func deviceLogsViewModelWantsToShowLoadingHud()
    func deviceLogsViewModelWantsToHideLoadingHud()
    func deviceLogsViewModelWantsToShareLogs(_ url: URL)
    func deviceLogsViewModelDidFail(error: Error)
}

final class DeviceLogsViewModel: DeinitPrintable, ObservableObject {
    deinit {
        print(deinitMessage)
        if let fileToDelete {
            try? FileManager.default.removeItem(at: fileToDelete)
        }
    }

    @Published private(set) var isLoading = true
    @Published private(set) var entries = [LogEntry]()
    @Published private(set) var error: Error?

    var formattedEntries: [String] { entries.map(logFormatter.format(entry:)) }

    private var fileToDelete: URL?

    private let logManager: LogManager
    private let logFormatter: LogFormatter
    let module: PassLogModule

    weak var delegate: DeviceLogsViewModelDelegate?

    init(module: PassLogModule) {
        self.module = module
        self.logManager = .init(module: module)
        self.logFormatter = .default
        self.loadLogs()
    }

    func loadLogs() {
        Task { @MainActor in
            defer { isLoading = false }
            do {
                isLoading = true
                entries = try await logManager.getLogEntries()
                isLoading = false
            } catch {
                self.error = error
            }
        }
    }

    func shareLogs() {
        Task { @MainActor in
            defer { delegate?.deviceLogsViewModelWantsToHideLoadingHud() }
            do {
                delegate?.deviceLogsViewModelWantsToShowLoadingHud()
                let file = FileManager.default.temporaryDirectory.appendingPathComponent(module.logFileName)
                let log = await logFormatter.format(entries: entries)
                try log.write(to: file, atomically: true, encoding: .utf8)
                fileToDelete = file
                delegate?.deviceLogsViewModelWantsToShareLogs(file)
            } catch {
                delegate?.deviceLogsViewModelDidFail(error: error)
            }
        }
    }
}
