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
import Factory
import Foundation

final class FullSyncProgressViewModel: ObservableObject {
    @Published private(set) var progresses = [VaultSyncProgress]()
    @Published private(set) var isDoneSynching = false
    private let vaultSyncEventStream = resolve(\SharedDataStreamContainer.vaultSyncEventStream)
    private let processVaultSyncEvent = resolve(\SharedUseCasesContainer.processVaultSyncEvent)
    private var cancellables = Set<AnyCancellable>()

    let mode: Mode

    enum Mode {
        case logIn, fullSync

        var isFullSync: Bool { self == .fullSync }
    }

    init(mode: Mode) {
        self.mode = mode

        vaultSyncEventStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self else { return }
                progresses = processVaultSyncEvent(event, with: progresses)
                if case .done = event {
                    isDoneSynching = true
                }
            }
            .store(in: &cancellables)
    }
}

extension FullSyncProgressViewModel {
    func numberOfSyncedVaults() -> Int {
        progresses.filter(\.isDone).count
    }
}
