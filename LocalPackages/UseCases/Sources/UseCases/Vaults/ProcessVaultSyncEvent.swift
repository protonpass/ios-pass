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
public protocol ProcessVaultSyncEventUseCase: Sendable {
    func execute(_ event: VaultSyncProgressEvent,
                 with progresses: [VaultSyncProgress]) -> [VaultSyncProgress]
}

public extension ProcessVaultSyncEventUseCase {
    func callAsFunction(_ event: VaultSyncProgressEvent,
                        with progresses: [VaultSyncProgress]) -> [VaultSyncProgress] {
        execute(event, with: progresses)
    }
}

public final class ProcessVaultSyncEvent: Sendable, ProcessVaultSyncEventUseCase {
    public init() {}

    public func execute(_ event: VaultSyncProgressEvent,
                        with progresses: [VaultSyncProgress]) -> [VaultSyncProgress] {
        switch event {
        case .done, .error, .initialization, .started:
            progresses

        case let .downloadedShares(shares):
            shares.map { .init(shareId: $0.shareID,
                               vault: nil,
                               itemsState: .loading) }

        case let .decryptedVault(vault):
            progresses.map { progress in
                if progress.shareId == vault.shareId {
                    progress.copy(vault: vault)
                } else {
                    progress
                }
            }

        case let .getRemoteItems(getProgress):
            progresses.map { progress in
                if progress.shareId == getProgress.shareId {
                    progress.copy(itemState: .download(downloaded: getProgress.downloaded,
                                                       total: getProgress.total))
                } else {
                    progress
                }
            }

        case let .decryptItems(decryptProgress):
            progresses.map { progress in
                if progress.shareId == decryptProgress.shareId {
                    progress.copy(itemState: .decrypt(decrypted: decryptProgress.decrypted,
                                                      total: decryptProgress.total))
                } else {
                    progress
                }
            }
        }
    }
}
