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

    enum State {
        case loading
        case loaded(String)
        case error(Error)
    }

    @Published private(set) var state = State.loading
    private var fileToDelete: URL?

    private let logManager: LogManager
    private let logFormatter: LogFormatter
    let type: DeviceLogType

    weak var delegate: DeviceLogsViewModelDelegate?

    init(type: DeviceLogType,
         logManager: LogManager) {
        self.type = type
        self.logManager = logManager
        self.logFormatter = .default
        self.loadLogs()
    }

    func loadLogs() {
        Task { @MainActor in
            do {
                state = .loading
                let entries = try await logManager.getLogEntries()
                    .filter { $0.subsystem == type.subsystem }
                let logs = await logFormatter.format(entries: entries.reversed())
                state = .loaded(logs)
            } catch {
                state = .error(error)
            }
        }
    }

    func shareLogs() {
        guard case .loaded(let logs) = state else { return }
        do {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent("Proton_Pass.log")
            try logs.write(to: file, atomically: true, encoding: .utf8)
            fileToDelete = file
            delegate?.deviceLogsViewModelWantsToShareLogs(file)
        } catch {
            delegate?.deviceLogsViewModelDidFail(error: error)
        }
    }
}
