//
// SyncProgress.swift
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

import Entities
import Foundation

// All the models related to vault sync progress feature

/// Object to track events when fetching items for vaults
public struct GetRemoteItemsProgress: Sendable {
    /// ID of the vault
    public let shareId: String
    /// Number of total items
    public let total: Int
    /// Number of downloaded items
    public let downloaded: Int

    public init(shareId: String, total: Int, downloaded: Int) {
        self.shareId = shareId
        self.total = total
        self.downloaded = downloaded
    }
}

/// Object to track events when decrypting fetched remote items
public struct DecryptItemsProgress: Sendable {
    /// ID of the vault
    public let shareId: String
    /// Number of total items
    public let total: Int
    /// Number of decrypted items
    public let decrypted: Int
}

/// Possible events when synching vaults
public enum VaultSyncProgressEvent: Sendable {
    /// An initial value for the sake of being able to make a `CurrentValueSubject`
    case initialization
    /// The sync progress has started (log in or full sync)
    case started
    /// Remote shares are fetched but not yet decrypted so no info like vault names or icons are known at this
    /// stage
    case downloadedShares([Share])
    /// A share is decrypted so we have the `Vault` object with all its visual info like  name and icon
    case decryptedVault(Share)
    /// Fetching remote items of a share
    case getRemoteItems(GetRemoteItemsProgress)
    /// Decrypting fetched remote items of a share
    case decryptItems(DecryptItemsProgress)
    /// The sync progress is done
    case done(hasUndecryptableShares: Bool)
    /// Error occurred
    case error(userId: String, error: any Error)
}

/// The sync progress of a given vault
public struct VaultSyncProgress: Sendable {
    public enum ItemsState: Sendable {
        case loading
        case download(downloaded: Int, total: Int)
        case decrypt(decrypted: Int, total: Int)
    }

    public let shareId: String
    public let vault: Share?
    public let itemsState: ItemsState

    public init(shareId: String, vault: Share?, itemsState: ItemsState) {
        self.shareId = shareId
        self.vault = vault
        self.itemsState = itemsState
    }

    /// Make a copy of the progress with a new `VaultState`
    public func copy(vault: Share?) -> Self {
        .init(shareId: shareId, vault: vault, itemsState: itemsState)
    }

    /// Make a copy of the progress with a new `ItemsState`
    public func copy(itemState: ItemsState) -> Self {
        .init(shareId: shareId, vault: vault, itemsState: itemState)
    }
}

extension VaultSyncProgress: Identifiable {
    public var id: String {
        shareId
    }
}

public extension VaultSyncProgress {
    var isDone: Bool {
        switch itemsState {
        case let .download(_, total):
            total == 0
        case let .decrypt(decrypted, total):
            decrypted >= total
        default:
            false
        }
    }

    var isEmpty: Bool {
        switch itemsState {
        case .loading:
            false
        case let .download(_, total):
            total == 0
        case let .decrypt(_, total):
            total == 0
        }
    }
}
