//
// ProcessVaultSyncEvent.swift
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

/// Process an event and map the current array of progresses
protocol ProcessVaultSyncEventUseCase: Sendable {
    func execute(_ event: VaultSyncProgressEvent,
                 with progresses: [VaultSyncProgress]) -> [VaultSyncProgress]
}

extension ProcessVaultSyncEventUseCase {
    func callAsFunction(_ event: VaultSyncProgressEvent,
                        with progresses: [VaultSyncProgress]) -> [VaultSyncProgress] {
        execute(event, with: progresses)
    }
}

final class ProcessVaultSyncEvent: Sendable, ProcessVaultSyncEventUseCase {
    init() {}

    func execute(_ event: VaultSyncProgressEvent,
                 with progresses: [VaultSyncProgress]) -> [VaultSyncProgress] {
        switch event {
        case .done, .initialization, .started:
            return progresses

        case let .downloadedShares(shares):
            return shares.map { .init(shareId: $0.shareID,
                                      vault: nil,
                                      itemsState: .loading) }

        case let .decryptedVault(vault):
            return progresses.map { progress in
                if progress.shareId == vault.shareId {
                    return progress.copy(vault: vault)
                } else {
                    return progress
                }
            }

        case let .getRemoteItems(getProgress):
            return progresses.map { progress in
                if progress.shareId == getProgress.shareId {
                    return progress.copy(itemState: .download(downloaded: getProgress.downloaded,
                                                              total: getProgress.total))
                } else {
                    return progress
                }
            }

        case let .decryptItems(decryptProgress):
            return progresses.map { progress in
                if progress.shareId == decryptProgress.shareId {
                    return progress.copy(itemState: .decrypt(decrypted: decryptProgress.decrypted,
                                                             total: decryptProgress.total))
                } else {
                    return progress
                }
            }
        }
    }
}
