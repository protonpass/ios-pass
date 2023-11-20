//
// EventSynchronizer.swift
// Proton Pass - Created on 16/11/2023.
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

import Core
import Entities
import Foundation
import ProtonCoreNetworking

/*
 Steps of a sync:
 1. Fetch all shares from remote.
 2. Compare recently fetched shares with local ones.
    For each new share do the full sync procedure.
    For each existing share, do the step 3 of the full sync procedure.

 Full sync procedure:
 1. Get the last eventID from remote
 2. Get the share data (keys, items...) and store in the local db
 3. Get events from api using last eventID
    a. Upsert `UpdatedItems`
    b. Delete `DeletedItemIDs`
    d. If `NewRotationID` is not null. Refresh the keys of the share.
    e. Upsert `LatestEventID` of the share.
    f. If `EventsPending` is `true`. Repeat this step with the given `LatestEventID`.
 */

public protocol EventSynchronizerProtocol: Actor {
    func sync() async throws -> Bool
}

public actor EventSynchronizer: EventSynchronizerProtocol {
    private let shareRepository: ShareRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let shareKeyRepository: ShareKeyRepositoryProtocol
    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
    private let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol
    private let userDataProvider: UserDataProvider
    private let logger: Logger

    public init(shareRepository: ShareRepositoryProtocol,
                itemRepository: ItemRepositoryProtocol,
                shareKeyRepository: ShareKeyRepositoryProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol,
                userDataProvider: UserDataProvider,
                logManager: LogManagerProtocol) {
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.shareKeyRepository = shareKeyRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.remoteSyncEventsDatasource = remoteSyncEventsDatasource
        self.userDataProvider = userDataProvider
        logger = .init(manager: logManager)
    }

    /// Return `true` if new events found
    @discardableResult
    public func sync() async throws -> Bool {
        // Need to sync 3 operations in 2 steps:
        // 1. Create & update sync
        // 2. Delete sync
        if Task.isCancelled {
            return false
        }

        let localShares = try await shareRepository.getShares()

        if Task.isCancelled {
            return false
        }

        let remoteShares = try await shareRepository.getRemoteShares()

        if Task.isCancelled {
            return false
        }

        var hasNewShareEvents = false
        // This is used to respond to sharing modifications that are not tied to events in the BE
        // making changes not visible to the user.
        if !remoteShares.isLooselyEqual(to: localShares.map(\.share)) {
            hasNewShareEvents = true

            // Update local shares
            let remainingLocalShares = localShares
                .filter { remoteShares.map(\.shareID).contains($0.share.shareID) }
            for share in remainingLocalShares {
                // A work around for a Core Data bug that fails the updates of booleans & numbers
                // We delete local shares instead of simply upserting and re-insert remote shares later on
                try await shareRepository.deleteShareLocally(shareId: share.share.shareID)
            }
            try await shareRepository.upsertShares(remoteShares)

            // Delete local shares if applicable
            let deletedLocalShares = localShares
                .filter { !remoteShares.map(\.shareID).contains($0.share.shareID) }
            if !deletedLocalShares.isEmpty {
                try await delete(shares: deletedLocalShares.map(\.share))
            }
        }

        let hasNewEvents = try await withThrowingTaskGroup(of: Bool.self,
                                                           returning: Bool.self) { taskGroup in
            taskGroup.addTask { [weak self] in
                guard let self else { return false }
                try Task.checkCancellation()

                return try await syncCreateAndUpdateEvents(localShares: localShares,
                                                           remoteShares: remoteShares)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return false }
                try Task.checkCancellation()

                return try await syncDeleteEvents(localShares: localShares,
                                                  remoteShares: remoteShares)
            }

            return try await taskGroup.contains { $0 }
        }

        return hasNewEvents || hasNewShareEvents
    }
}

// MARK: Private APIs

private extension EventSynchronizer {
    func delete(shares: [Share]) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in shares {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    let shareId = share.shareID

                    if Task.isCancelled {
                        return
                    }
                    try await shareRepository.deleteShareLocally(shareId: shareId)
                    if Task.isCancelled {
                        return
                    }
                    try await itemRepository.deleteAllItemsLocally(shareId: shareId)
                }
            }
        }
    }

    /// Return `true` if new events found
    func syncCreateAndUpdateEvents(localShares: [SymmetricallyEncryptedShare],
                                   remoteShares: [Share]) async throws -> Bool {
        // Compare remote shares against local shares
        try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for remoteShare in remoteShares {
                // Task group returning `true` if new events found, `false` other wise
                taskGroup.addTask { [weak self] in
                    guard let self else { return false }
                    var hasNewEvents = false
                    if localShares.contains(where: { $0.share.shareID == remoteShare.shareID }) {
                        // Existing share
                        logger.trace("Existing share \(remoteShare.shareID)")
                        try await sync(share: remoteShare, hasNewEvents: &hasNewEvents)
                    } else {
                        // New share
                        logger.debug("New share \(remoteShare.shareID)")
                        hasNewEvents = true
                        let shareId = remoteShare.shareID

                        do {
                            try Task.checkCancellation()
                            _ = try await shareKeyRepository.refreshKeys(shareId: shareId)
                            try Task.checkCancellation()
                            try await shareRepository.upsertShares([remoteShare])
                            try Task.checkCancellation()
                            try await itemRepository.refreshItems(shareId: shareId)
                        } catch {
                            if let passError = error as? PassError,
                               case let .crypto(reason) = passError,
                               case .inactiveUserKey = reason {
                                // Ignore the case where user key is inactive
                                logger.warning(reason.debugDescription)
                            } else {
                                throw error
                            }
                        }
                    }
                    return hasNewEvents
                }
            }

            return try await taskGroup.contains { $0 }
        }
    }

    /// Return `true` if new events found
    func syncDeleteEvents(localShares: [SymmetricallyEncryptedShare],
                          remoteShares: [Share]) async throws -> Bool {
        // Compare local shares against remote shares
        try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for localShare in localShares {
                // Task group returning `true` if new events found, `false` other wise
                taskGroup.addTask { [weak self] in
                    guard let self else { return false }
                    let shareId = localShare.share.shareID
                    if !remoteShares.contains(where: { $0.shareID == shareId }) {
                        try Task.checkCancellation()
                        // We can blindly remove the local share and its items from the database
                        // but better to double check by asking the server
                        // and compare with a known error code "DISABLED_SHARE: 300004"
                        do {
                            // Expect an error here so passing a dummy boolean
                            logger.trace("Deleted share \(shareId)")
                            var dummyBoolean = false
                            try await sync(share: localShare.share, hasNewEvents: &dummyBoolean)
                        } catch {
                            if let responseError = error as? ResponseError,
                               responseError.responseCode == 300_004 {
                                // Confirmed that the vault is really deleted
                                // safe to delete it locally
                                try Task.checkCancellation()
                                try await shareRepository.deleteShareLocally(shareId: shareId)
                                try Task.checkCancellation()
                                try await itemRepository.deleteAllItemsLocally(shareId: shareId)
                                return true
                            }
                            throw error
                        }
                    }
                    return false
                }
            }

            return try await taskGroup.contains { $0 }
        }
    }

    /// Sync a single share. Can be a recursion if share has many events
    func sync(share: Share, hasNewEvents: inout Bool) async throws {
        let userId = try userDataProvider.getUserId()
        let shareId = share.shareID
        logger.trace("Syncing share \(shareId)")
        try Task.checkCancellation()
        let lastEventId = try await shareEventIDRepository.getLastEventId(forceRefresh: false,
                                                                          userId: userId,
                                                                          shareId: shareId)
        try Task.checkCancellation()
        let events = try await remoteSyncEventsDatasource.getEvents(shareId: shareId,
                                                                    lastEventId: lastEventId)

        try await shareEventIDRepository.upsertLastEventId(userId: userId,
                                                           shareId: shareId,
                                                           lastEventId: events.latestEventID)
        try Task.checkCancellation()
        if events.fullRefresh {
            logger.info("Force full sync for share \(shareId)")
            hasNewEvents = true
            try await itemRepository.refreshItems(shareId: shareId)
            return
        }

        try Task.checkCancellation()
        if let updatedShare = events.updatedShare {
            hasNewEvents = true
            logger.trace("Found updated share \(shareId)")
            try await shareRepository.upsertShares([updatedShare])
        }

        try Task.checkCancellation()
        if !events.updatedItems.isEmpty {
            hasNewEvents = true
            logger.trace("Found \(events.updatedItems.count) updated items for share \(shareId)")
            try await itemRepository.upsertItems(events.updatedItems, shareId: shareId)
        }

        try Task.checkCancellation()
        if !events.deletedItemIDs.isEmpty {
            hasNewEvents = true
            logger.trace("Found \(events.deletedItemIDs.count) deleted items for share \(shareId)")
            try await itemRepository.deleteItemsLocally(itemIds: events.deletedItemIDs,
                                                        shareId: shareId)
        }
        try Task.checkCancellation()
        if !events.lastUseItems.isEmpty {
            hasNewEvents = true
            logger.trace("Found \(events.lastUseItems.count) lastUseItem for share \(shareId)")
            try await itemRepository.update(lastUseItems: events.lastUseItems, shareId: shareId)
        }

        try Task.checkCancellation()
        if events.newKeyRotation != nil {
            hasNewEvents = true
            logger.trace("Had new rotation ID for share \(shareId)")
            _ = try await shareKeyRepository.refreshKeys(shareId: shareId)
        }

        try Task.checkCancellation()
        if events.eventsPending {
            logger.trace("Still have more events for share \(shareId)")
            try await sync(share: share, hasNewEvents: &hasNewEvents)
        }
    }
}
