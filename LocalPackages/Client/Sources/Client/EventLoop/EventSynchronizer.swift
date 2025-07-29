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
import ProtonCoreFeatureFlags
import ProtonCoreNetworking

/*
 Steps of a sync:
 1. Fetch all shares from remote and local
 2. Compare recently fetched shares with local ones.
    if discrepancies found update or remove local shares as remote share are the source of truth.

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
    func sync(userId: String) async throws -> Bool
}

public actor EventSynchronizer: EventSynchronizerProtocol {
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareKeyRepository: any ShareKeyRepositoryProtocol
    private let shareEventIDRepository: any ShareEventIDRepositoryProtocol
    private let remoteSyncEventsDatasource: any RemoteSyncEventsDatasourceProtocol
    private let aliasRepository: any AliasRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(shareRepository: any ShareRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol,
                shareKeyRepository: any ShareKeyRepositoryProtocol,
                shareEventIDRepository: any ShareEventIDRepositoryProtocol,
                remoteSyncEventsDatasource: any RemoteSyncEventsDatasourceProtocol,
                aliasRepository: any AliasRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.shareKeyRepository = shareKeyRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.remoteSyncEventsDatasource = remoteSyncEventsDatasource
        self.aliasRepository = aliasRepository
        self.accessRepository = accessRepository
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    /// Return `true` if new events found
    @discardableResult
    public func sync(userId: String) async throws -> Bool {
        // Need to sync 3 operations in 2 steps:
        // 1. Create & update sync
        // 2. Delete sync

        logger.trace("Start sync: fetching local and remote shares + alias sync")
        async let fetchLocalShares = shareRepository.getShares(userId: userId)
        async let fetchRemoteShares = shareRepository.getDecryptedRemoteShares(userId: userId)
        async let fetchAliasSync: Void = aliasSync(userId: userId)

        if Task.isCancelled {
            return false
        }

        var (localShares, remoteShares) = try await (fetchLocalShares, fetchRemoteShares)
        logger.trace("Finished fetching \(localShares.count) local and \(remoteShares.shares.count) remote shares")

        let updatedShares = try await removeSuperfluousLocalShares(userId: userId,
                                                                   localShares: localShares,
                                                                   remoteShares: remoteShares.shares)
        if updatedShares {
            if Task.isCancelled {
                return true
            }
            logger.trace("Updating local shares with latest information after previous local deletion")

            /// Updating the local shares with the latest information as `updatedShares` notifies of local
            /// share changes.
            localShares = try await shareRepository.getShares(userId: userId)
        }
        if Task.isCancelled {
            return false
        }

        let hasNewEvents = try await syncCreateAndUpdateEvents(userId: userId,
                                                               localShares: localShares,
                                                               remoteShares: remoteShares.shares)
        // swiftlint:disable:next todo
        // TODO: Check alias sync QA
        // Must keep an eye on this `aliasSync` await as there could be lot of aliases to sync for a user
        // meaning
        // this could impact negatively the entire sync process.
        // We should stress test this with QA on SL account have lots of aliases to sync to be sure this does
        // not
        // break anything
        _ = try await fetchAliasSync

        return hasNewEvents || updatedShares
    }
}

// MARK: Private APIs

// MARK: - Sharing Events

private extension EventSynchronizer {
    func removeSuperfluousLocalShares(userId: String,
                                      localShares: [SymmetricallyEncryptedShare],
                                      remoteShares: [Share]) async throws -> Bool {
        // This is used to respond to sharing modifications that are not tied to events in the BE
        // making changes not visible to the user.
        logger.trace("Started removing superfluous local shares")

        if !remoteShares.isLooselyEqual(to: localShares.map(\.share)) {
            // Update local shares based on remote shares that are the source of truth
            let remoteShareIDs = Set(remoteShares.map(\.shareID))

            // Filter local shares not present in remote shares
            let deletedLocalShares = localShares.filter { !remoteShareIDs.contains($0.share.shareID) }

            let shareIds = deletedLocalShares.map(\.share.shareID).joined(separator: ", ")
            logger.trace("Deleting following \(shareIds.count) shareIds \(shareIds)")

            // Delete local shares if there are any to delete
            if !deletedLocalShares.isEmpty {
                try await delete(userId: userId, shares: deletedLocalShares)
            }
            logger.trace("Finished deleting superfluous local shares")

            return true
        }
        return false
    }

    func delete(userId: String, shares: [SymmetricallyEncryptedShare]) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in shares {
                let shareId = share.share.shareID
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await shareRepository.deleteShareLocally(userId: userId, shareId: shareId)
                }
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await itemRepository.deleteAllItemsLocally(shareId: shareId)
                }
            }
        }
    }
}

// MARK: - Sync Utils

private extension EventSynchronizer {
    /// Return `true` if new events found
    func syncCreateAndUpdateEvents(userId: String,
                                   localShares: [SymmetricallyEncryptedShare],
                                   remoteShares: [Share]) async throws -> Bool {
        let localShareIDs = Set(localShares.map(\.share.shareID))
        logger.trace("Start syncCreateAndUpdateEvents function")

        return try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for remoteShare in remoteShares {
                let shareId = remoteShare.shareID
                taskGroup.addTask { [weak self] in
                    guard let self else { return false }

                    let isExistingShare = localShareIDs.contains(shareId)
                    let loggerMessage = isExistingShare ? "Existing share \(shareId)" :
                        "New share \(shareId)"
                    logger.trace(loggerMessage)

                    if isExistingShare {
                        return try await handleExistingShare(userId: userId, remoteShare: remoteShare)
                    } else {
                        try await handleNewShare(userId: userId, remoteShare: remoteShare)
                        return true
                    }
                }
            }

            var foundNewEvent = false
            for try await hasNewEvents in taskGroup where hasNewEvents == true {
                foundNewEvent = true
            }

            return foundNewEvent
        }
    }

    /// Handle existing share processing
    func handleExistingShare(userId: String, remoteShare: Share) async throws -> Bool {
        logger.trace("Start update of existing shares")

        try await shareRepository.upsertShares(userId: userId, shares: [remoteShare])
        try Task.checkCancellation()
        return try await sync(userId: userId, share: remoteShare)
    }

    /// Handle new share processing
    func handleNewShare(userId: String, remoteShare: Share) async throws {
        let shareId = remoteShare.shareID
        logger.trace("Start handle of new shares")

        do {
            try Task.checkCancellation()
            async let upsertShares: Void = shareRepository.upsertShares(userId: userId, shares: [remoteShare])
            async let refreshItems: Void = itemRepository.refreshItems(userId: userId, shareId: shareId)
            try Task.checkCancellation()
            _ = try await (upsertShares, refreshItems)
        } catch {
            if error.isInactiveUserKey {
                logger.warning(error.localizedDebugDescription)
            } else {
                throw error
            }
        }
    }

    /// Sync a single share. Can be a recursion if share has many events
    func sync(userId: String, share: Share) async throws -> Bool {
        logger.trace("Syncing share \(share.shareId)")
        return try await performSyncOperations(userId: userId, share: share)
    }

    /// Perform synchronization operations
    func performSyncOperations(userId: String, share: Share) async throws -> Bool {
        try Task.checkCancellation()
        let shareId = share.shareId
        let lastEventId = try await shareEventIDRepository.getLastEventId(forceRefresh: false,
                                                                          userId: userId,
                                                                          shareId: shareId)
        try Task.checkCancellation()
        let events = try await remoteSyncEventsDatasource.getEvents(userId: userId,
                                                                    shareId: shareId,
                                                                    lastEventId: lastEventId)
        try Task.checkCancellation()
        try await shareEventIDRepository.upsertLastEventId(userId: userId,
                                                           shareId: shareId,
                                                           lastEventId: events.latestEventID)
        try Task.checkCancellation()

        let hasNewEvents = try await processEvents(userId: userId, events: events, share: share)

        if events.eventsPending {
            logger.trace("Still have more events for share \(shareId)")
            return try await performSyncOperations(userId: userId, share: share)
        }
        return hasNewEvents
    }

    /// Process the events from synchronization
    func processEvents(userId: String, events: SyncEvents, share: Share) async throws -> Bool {
        if events.fullRefresh {
            logger.info("Force full sync for share \(share.shareId)")
            try await itemRepository.refreshItems(userId: userId, shareId: share.shareId)
            return true
        } else {
            return try await processEventDetails(userId: userId, events: events, share: share)
        }
    }

    /// Process the detailed parts of the events
    func processEventDetails(userId: String, events: SyncEvents, share: Share) async throws -> Bool {
        let shareId = share.shareId

        var hasNewEvents = false
        try Task.checkCancellation()
        if let updatedShare = events.updatedShare {
            hasNewEvents = try await handleUpdateEvent(description: "updated",
                                                       count: 1,
                                                       shareId: shareId) { [weak self] in
                guard let self else {
                    return
                }
                try await shareRepository.upsertShares(userId: userId, shares: [updatedShare])
            }
        }

        try Task.checkCancellation()
        if !events.updatedItems.isEmpty {
            hasNewEvents = try await handleUpdateEvent(description: "updated items",
                                                       count: events.updatedItems.count,
                                                       shareId: shareId) { [weak self] in
                guard let self else {
                    return
                }
                try await itemRepository.upsertItems(userId: userId,
                                                     items: events.updatedItems,
                                                     shareId: shareId)
            }
        }

        try Task.checkCancellation()
        if !events.deletedItemIDs.isEmpty {
            hasNewEvents = try await handleUpdateEvent(description: "deleted items",
                                                       count: events.deletedItemIDs.count,
                                                       shareId: shareId) { [weak self] in
                guard let self else {
                    return
                }
                try await itemRepository.deleteItemsLocally(itemIds: events.deletedItemIDs,
                                                            shareId: shareId)
            }
        }

        try Task.checkCancellation()
        if !events.lastUseItems.isEmpty {
            hasNewEvents = try await handleUpdateEvent(description: "lastUseItem",
                                                       count: events.lastUseItems.count,
                                                       shareId: shareId) { [weak self] in
                guard let self else {
                    return
                }
                try await itemRepository.update(lastUseItems: events.lastUseItems, shareId: shareId)
            }
        }

        try Task.checkCancellation()
        if events.newKeyRotation != nil {
            hasNewEvents = try await handleUpdateEvent(description: "new rotation ID",
                                                       count: 1,
                                                       shareId: shareId) { [weak self] in
                guard let self else {
                    return
                }
                _ = try await shareKeyRepository.refreshKeys(userId: userId, shareId: shareId)
            }
        }

        return hasNewEvents
    }

    /// Handle an update event, logging and setting the flag
    func handleUpdateEvent(description: String,
                           count: Int,
                           shareId: ShareID,
                           operation: @escaping () async throws -> Void) async throws -> Bool {
        logger.trace("Found \(count) \(description) for share \(shareId)")
        try await operation()
        return true
    }
}

// MARK: - Simplelogin alias sync

private extension EventSynchronizer {
    func aliasSync(userId: String) async throws {
        let userAliasSyncSettings = try await accessRepository.getAccess(userId: userId).access.userData
        guard userAliasSyncSettings.aliasSyncEnabled,
              userAliasSyncSettings.pendingAliasToSync > 0,
              let shareId = userAliasSyncSettings.defaultShareID else {
            return
        }
        var sinceLastToken: String?

        while true {
            let paginatedAlias = try await aliasRepository.getPendingAliasesToSync(userId: userId,
                                                                                   since: sinceLastToken)

            if paginatedAlias.aliases.isEmpty {
                break
            }

            let itemsContent = Dictionary(uniqueKeysWithValues: paginatedAlias.aliases.map { alias in
                (alias.pendingAliasID, ItemContentProtobuf(name: alias.aliasEmail,
                                                           note: "",
                                                           itemUuid: UUID().uuidString,
                                                           data: .alias,
                                                           customFields: []))
            })

            _ = try await itemRepository.createPendingAliasesItem(userId: userId,
                                                                  shareId: shareId,
                                                                  itemsContent: itemsContent)

            // Move to the next page
            sinceLastToken = paginatedAlias.lastToken
        }
    }
}
