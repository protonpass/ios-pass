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

import Foundation

protocol ExtractLogsToFileUseCase: Sendable {
    func execute(to fileName: String) async throws -> URL?
}

extension ExtractLogsToFileUseCase {
    func callAsFunction(to fileName: String) async throws -> URL? {
        try await execute(to: fileName)
    }
}

final class ExtractLogsToFile: ExtractLogsToFileUseCase {
    private let extractLogsToDataUseCase: ExtractLogsToDataUseCase

    init(extractLogsToDataUseCase: ExtractLogsToDataUseCase) {
        self.extractLogsToDataUseCase = extractLogsToDataUseCase
    }

    func execute(to fileName: String) async throws -> URL? {
        guard let logsData = try await extractLogsToDataUseCase(),
              let logs = logsData.utf8DataToString else {
            return nil
        }

        let file = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try logs.write(to: file, atomically: true, encoding: .utf8)
        return file
    }
}

//
// final class LogsViewModel: DeinitPrintable, ObservableObject {
//    deinit {
//        print(deinitMessage)
//        if let fileToDelete {
//            try? FileManager.default.removeItem(at: fileToDelete)
//        }
//    }
//
//    @Published private(set) var isLoading = true
//    @Published private(set) var entries = [LogEntry]()
//    @Published private(set) var error: Error?
//
//    var formattedEntries: [String] { entries.map(logFormatter.format(entry:)) }
//
//    private var fileToDelete: URL?
//
//    private let logManager: LogManager
//    private let logFormatter: LogFormatter
//    let module: PassLogModule
//
//    weak var delegate: LogsViewModelDelegate?
//
//    init(module: PassLogModule) {
//        self.module = module
//        logManager = .init(module: module)
//        logFormatter = .default
//        loadLogs()
//    }
//
//    func loadLogs() {
//        Task { @MainActor in
//            defer { isLoading = false }
//            do {
//                isLoading = true
//                entries = try await logManager.getLogEntries()
//                isLoading = false
//            } catch {
//                self.error = error
//            }
//        }
//    }
//
//    func shareLogs() {
//        Task { @MainActor in
//            do {
//                delegate?.logsViewModelWantsToShowSpinner()
//                let fileName = module.logFileName(suffix: Bundle.main.gitCommitHash ?? "?")
//                let file = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
//                let log = await logFormatter.format(entries: entries)
//                try log.write(to: file, atomically: true, encoding: .utf8)
//                fileToDelete = file
//                delegate?.logsViewModelWantsToHideSpinner()
//                delegate?.logsViewModelWantsToShareLogs(file)
//            } catch {
//                delegate?.logsViewModelWantsToHideSpinner()
//                delegate?.logsViewModelDidEncounter(error: error)
//            }
//        }
//    }
// }
