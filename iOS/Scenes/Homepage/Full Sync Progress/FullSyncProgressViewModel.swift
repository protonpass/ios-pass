//
// FullSyncProgressViewModel.swift
// Proton Pass - Created on 11/09/2023.
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
import DIComposition
import Entities
import FactoryKit
import Foundation
import Screens
import UseCases

/// Follows one full sync of one user. Failures stay on screen with a retry button,
/// every other outcome is handed to `onFinish` so the owner can remove the progress UI.
@MainActor
@Observable
final class FullSyncProgressViewModel {
    private(set) var operation: FullSyncOperation
    let presentation: FullSyncPresentation

    private let fullContentSync = dependency(\UseCasesContainer.fullContentSync)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let createLogsFile = dependency(\UseCasesContainer.createLogsFile)
    private let onFinish: (FullSyncOperation, FullSyncOperation.Outcome) -> Void

    @ObservationIgnored
    private var waitForOutcomeTask: Task<Void, Never>?

    var error: (any Error)? {
        guard case let .failed(error) = operation.outcome, !error.isInactiveUserKey else { return nil }
        return error
    }

    var progresses: [VaultSyncProgress] {
        operation.progresses
    }

    var numberOfSyncedVaults: Int {
        progresses.count(where: \.isDone)
    }

    init(operation: FullSyncOperation,
         onFinish: @escaping (FullSyncOperation, FullSyncOperation.Outcome) -> Void) {
        self.operation = operation
        presentation = operation.presentation
        self.onFinish = onFinish
        track(operation)
    }

    func track(_ operation: FullSyncOperation) {
        self.operation = operation
        waitForOutcomeTask?.cancel()
        waitForOutcomeTask = Task { [weak self] in
            let outcome = await operation.result()
            guard let self, !Task.isCancelled else { return }
            if case let .failed(error) = outcome, !error.isInactiveUserKey {
                return
            }
            onFinish(operation, outcome)
        }
    }

    func retry() {
        track(fullContentSync.start(userId: operation.userId,
                                    presentation: presentation,
                                    shouldStopEventLoop: true))
    }

    func shareHostAppLogs() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let logsUrl = try await createLogsFile(for: PassModule.hostApp) {
                    router.present(for: .shareLogs(logsUrl))
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
