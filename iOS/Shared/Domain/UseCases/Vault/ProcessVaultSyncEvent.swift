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

/// Process an event and update the current array of progresses
protocol ProcessVaultSyncEventUseCase: Sendable {
    func execute(_ event: VaultSyncProgressEvent, with progresses: inout [VaultSyncProgress])
}

extension ProcessVaultSyncEventUseCase {
    func callAsFunction(_ event: VaultSyncProgressEvent, with progresses: inout [VaultSyncProgress]) {
        execute(event, with: &progresses)
    }
}

final class ProcessVaultSyncEvent: Sendable, ProcessVaultSyncEventUseCase {
    init() {}

    func execute(_ event: VaultSyncProgressEvent, with progresses: inout [VaultSyncProgress]) {
        switch event {
        case .done, .started:
            break

        case let .downloadedShares(shares):
            progresses = shares.map { .init(shareId: $0.shareID,
                                            vaultState: .unknown,
                                            itemsState: .loading) }

        case let .decryptedVault(vault):
            progresses = progresses.map { progress in
                if progress.shareId == vault.shareId {
                    return progress.copy(vaultState: .known(vault))
                } else {
                    return progress
                }
            }

        case let .getRemoteItems(getRemoteItemsProgress):
            progresses = progresses.map { progress in
                if progress.shareId == getRemoteItemsProgress.shareId {
                    return progress.copy(itemState: .download(downloaded: getRemoteItemsProgress.downloaded,
                                                              total: getRemoteItemsProgress.total))
                } else {
                    return progress
                }
            }

        case let .decryptItems(decryptItemsProgress):
            progresses = progresses.map { progress in
                if progress.shareId == decryptItemsProgress.shareId {
                    return progress.copy(itemState: .decrypt(decrypted: decryptItemsProgress.decrypted,
                                                             total: decryptItemsProgress.total))
                } else {
                    return progress
                }
            }
        }
    }
}
