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
import Combine
import Core
import Factory
import Foundation
import Macro

@MainActor
final class FullSyncProgressViewModel: ObservableObject {
    @Published private(set) var progresses = [VaultSyncProgress]()
    @Published private(set) var error: (any Error)?
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let processVaultSyncEvent = resolve(\SharedUseCasesContainer.processVaultSyncEvent)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var cancellables = Set<AnyCancellable>()

    private var userId: String?
    let mode: Mode

    enum Mode {
        case logIn, fullSync

        var isFullSync: Bool { self == .fullSync }
    }

    init(mode: Mode) {
        self.mode = mode
        appContentManager.vaultSyncEventStream
            .subscribe(on: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case let .done(hasUndecryptableShares):
                    if hasUndecryptableShares {
                        dismissAndDisplayUndecryptableSharesBanner()
                    } else {
                        dismissAndNotifySyncCompletion()
                    }

                case let .error(userId, error):
                    if error.isInactiveUserKey {
                        dismissAndDisplayUndecryptableSharesBanner()
                    } else {
                        self.userId = userId
                        self.error = error
                    }

                default:
                    progresses = processVaultSyncEvent(event, with: progresses)
                }
            }
            .store(in: &cancellables)
    }
}

extension FullSyncProgressViewModel {
    func numberOfSyncedVaults() -> Int {
        progresses.filter(\.isDone).count
    }

    func retry() async {
        guard let userId else {
            assertionFailure("Failed to full sync. No userID found")
            return
        }
        self.userId = nil
        error = nil
        progresses.removeAll()
        await appContentManager.fullSync(userId: userId)
    }
}

private extension FullSyncProgressViewModel {
    func dismissAndDisplayUndecryptableSharesBanner() {
        router.present(for: .undecryptableSharesBanner(dismissTopSheetBeforeShowing: mode.isFullSync))
    }

    func dismissAndNotifySyncCompletion() {
        if mode.isFullSync {
            router.display(element: .infosMessage(#localized("Sync complete"),
                                                  config: .init(dismissBeforeShowing: true)))
        } else {
            router.display(element: .infosMessage(#localized("The app is now ready to use"),
                                                  showWhenNoSheets: true))
        }
    }
}
