//
// UserEventsSynchronizer.swift
// Proton Pass - Created on 16/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import Foundation

public struct UserEventsSyncResult: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let dataUpdated = Self(rawValue: 1 << 0)
    public static let invitesChanged = Self(rawValue: 1 << 1)
    public static let refreshUser = Self(rawValue: 1 << 2)
    public static let fullRefreshNeeded = Self(rawValue: 1 << 3)
    public static let groupInvitesChanged = Self(rawValue: 1 << 4)
}

public protocol UserEventsSynchronizerProtocol: Sendable {
    func sync(userId: String) async throws -> UserEventsSyncResult
}


//TODO: All logic should be local
public final class UserEventsSynchronizer: UserEventsSynchronizerProtocol {
    private let localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol
    private let remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let inviteRepository: any InviteRepositoryProtocol
    private let simpleLoginNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol
    private let logger: Logger
    private let maxPerRoundFetchCycle = 10

    public init(localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol,
                remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol,
                itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                inviteRepository: any InviteRepositoryProtocol,
                simpleLoginNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol,
                logManager: any LogManagerProtocol) {
        self.localUserEventIdDatasource = localUserEventIdDatasource
        self.remoteUserEventsDatasource = remoteUserEventsDatasource
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.accessRepository = accessRepository
        self.inviteRepository = inviteRepository
        self.simpleLoginNoteSynchronizer = simpleLoginNoteSynchronizer
        logger = .init(manager: logManager)
    }
}

public extension UserEventsSynchronizer {
    func sync(userId: String) async throws -> UserEventsSyncResult {
        logger.trace("Syncing user events for user \(userId)")
        guard let lastEventId = try await localUserEventIdDatasource.getLastEventId(userId: userId) else {
            logger.warning("No local user event ID for user \(userId). Force full refresh.")
            return [.fullRefreshNeeded]
        }

        let userSyncResult = try await parseUserEvents(userId: userId,
                                                       lastEventId: lastEventId)
        logger.info("Finished syncing with user events for user \(userId)")
        return userSyncResult
    }
}

private extension UserEventsSynchronizer {
    func parseUserEvents(userId: String, lastEventId: String) async throws -> UserEventsSyncResult {
        var result: UserEventsSyncResult = []
        var currentCycle = 0

        while currentCycle <= maxPerRoundFetchCycle {
            let events = try await remoteUserEventsDatasource.getUserEvents(userId: userId,
                                                                            lastEventId: lastEventId)

            try await process(events: events, for: userId)

            // Combine flags using OptionSet
            if events.dataUpdated { result.insert(.dataUpdated) }
            if events.invitesChanged != nil { result.insert(.invitesChanged) }
            if events.groupInvitesChanged != nil { result.insert(.groupInvitesChanged) }
            if events.refreshUser { result.insert(.refreshUser) }
            if events.fullRefresh { result.insert(.fullRefreshNeeded) }

            try await localUserEventIdDatasource.upsertLastEventId(userId: userId,
                                                                   lastEventId: events.lastEventID)

            guard events.eventsPending else { break }
            currentCycle += 1
        }

        return result
    }

    // All todos need to be done in upcoming MRs for group invites and folders
    func process(events: UserEvents, for userId: String) async throws {
        async let updatedItems: () = processUpdatedItems(events.itemsUpdated, userId: userId)
        async let deletedItems: () = processDeletedItems(events.itemsDeleted, userId: userId)
        async let aliasNotesChanged: () = processAliasNoteChangedItems(events.aliasNoteChanged, userId: userId)
        async let createdShares: () = processCreatedShares(events.sharesCreated, userId: userId)
        async let updatedShares: () = processUpdatedShares(events.sharesUpdated, userId: userId)
        async let deletedShares: () = processDeletedShares(events.sharesDeleted, userId: userId)
        // swiftlint:disable:next todo
        // TODO: folder to be implemented in the folder ticket mr
//        async let foldersUpdated: () = processSharesToCreate(events.foldersUpdated, userId: userId)
//        async let foldersDeleted: () = processInviteChanges(inviteChanges: events.foldersDeleted, userId: userId)
        async let invites: () = processInviteChanges(inviteChanges: events.invitesChanged, userId: userId)
        // swiftlint:disable:next todo
        // TODO: Group invite to be added to the group sharing MR
//        async let groupInvites: () = processInviteChanges(inviteChanges: events.groupInvitesChanged, userId:
//        userId)
        // swiftlint:disable:next todo
        // TODO: share with invite to be added to the group sharing MR that contains changes to invite logic and serices
//        async let inviteCreatedShares: () = processInviteChanges(inviteChanges: events.sharesWithInvitesToCreate,
//        userId: userId)
        _ = try await (updatedItems,
                       deletedItems,
                       aliasNotesChanged,
                       createdShares,
                       updatedShares,
                       deletedShares,
                       invites)
    }

    func processUpdatedItems(_ updatedItems: [ItemEvent], userId: String) async throws {
        guard !updatedItems.isEmpty else {
            logger.trace("No updated items for user \(userId)")
            return
        }
        logger.trace("Refreshing \(updatedItems.count) updated items for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for updatedItem in updatedItems {
                taskGroup.addTask { [itemRepository, userId] in
                    try await itemRepository.refreshItem(userId: userId,
                                                         shareId: updatedItem.shareID,
                                                         itemId: updatedItem.itemID,
                                                         eventToken: updatedItem.eventToken)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processDeletedItems(_ deletedItems: [ItemEvent], userId: String) async throws {
        guard !deletedItems.isEmpty else {
            logger.trace("No deleted items for user \(userId)")
            return
        }
        logger.trace("Deleting \(deletedItems.count) items for user \(userId)")
        try await itemRepository.deleteItemsLocally(items: deletedItems)
    }

    //TODO: Need to add eventoken
    func processAliasNoteChangedItems(_ aliasNoteChangedItems: [ItemEvent],
                                      userId: String) async throws {
        guard !aliasNoteChangedItems.isEmpty else {
            logger.trace("No alias note changed for user \(userId)")
            return
        }
        logger.trace("Syncing SL note for \(aliasNoteChangedItems.count) items for user \(userId)")
        _ = try await simpleLoginNoteSynchronizer.syncAliases(userId: userId,
                                                              aliases: aliasNoteChangedItems)
    }

    func processUpdatedShares(_ updatedShares: [ShareEvent], userId: String) async throws {
        guard !updatedShares.isEmpty else {
            logger.trace("No updated shares for user \(userId)")
            return
        }
        logger.trace("Refreshing \(updatedShares.count) shares for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for updatedShare in updatedShares {
                taskGroup.addTask { [shareRepository, userId] in
                    try await shareRepository.refreshShare(userId: userId,
                                                           shareId: updatedShare.shareID,
                                                           eventToken: updatedShare.eventToken)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processCreatedShares(_ createdShares: [ShareEvent], userId: String) async throws {
        guard !createdShares.isEmpty else {
            logger.trace("No shares to create for user \(userId)")
            return
        }
        logger.trace("Creating \(createdShares.count) shares for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for newShare in createdShares {
                taskGroup.addTask { [shareRepository, itemRepository, userId] in
                    // We need to start for a fresh data state
                    if let localShare = try await shareRepository.getShare(shareId: newShare.shareID) {
                        try await shareRepository.deleteShareLocally(userId: userId, shareId: localShare.shareID)
                        try await itemRepository.deleteAllItemsLocally(shareId: localShare.shareID)
                    }
                    try await shareRepository.refreshShare(userId: userId,
                                                           shareId: newShare.shareID,
                                                           eventToken: newShare.eventToken)
                    try await itemRepository.refreshItems(userId: userId, shareId: newShare.shareID)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processDeletedShares(_ deletedShares: [ShareEvent], userId: String) async throws {
        guard !deletedShares.isEmpty else {
            logger.trace("No deleted shares for user \(userId)")
            return
        }
        logger.trace("Deleting \(deletedShares.count) shares for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in deletedShares {
                taskGroup.addTask { [shareRepository, itemRepository, userId] in
                    async let deleteShare: Void = shareRepository.deleteShareLocally(userId: userId,
                                                                                     shareId: share.shareID)
                    async let deleteItems: Void = itemRepository.deleteAllItemsLocally(shareId: share.shareID)
                    _ = try await (deleteShare, deleteItems)
                }
            }
            try await taskGroup.waitForAll()
        }
    }

    func processInviteChanges(inviteChanges: PendingChangeEvent?,
                              userId: String) async throws {
        guard inviteChanges != nil else {
            logger.trace("No invite changes for user \(userId)")
            return
        }
        try await inviteRepository.refreshInvites(userId: userId)
    }
}
