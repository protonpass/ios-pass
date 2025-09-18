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

/// The result of user events sync giving information to act upon on
public struct UserEventsSyncResult: Sendable, Equatable {
    /// Items or shares were updated, a UI refresh is needed to reflect updated data
    public let dataUpdated: Bool

    /// Invites were updated, go update the invite banner
    public let invitesChanged: Bool

    /// User's plan has changed (e.g free -> paid), go fetch the updated plan
    public let planChanged: Bool

    /// Force full sync (e.g users haven't used the app for a long period and last event ID is obsolete)
    public let fullRefreshNeeded: Bool

    public init(dataUpdated: Bool,
                invitesChanged: Bool,
                planChanged: Bool,
                fullRefreshNeeded: Bool) {
        self.dataUpdated = dataUpdated
        self.invitesChanged = invitesChanged
        self.planChanged = planChanged
        self.fullRefreshNeeded = fullRefreshNeeded
    }
}

public protocol UserEventsSynchronizerProtocol: Sendable {
    func sync(userId: String) async throws -> UserEventsSyncResult
}

public actor UserEventsSynchronizer: UserEventsSynchronizerProtocol {
    private let localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol
    private let remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let inviteRepository: any InviteRepositoryProtocol
    private let simpleLoginNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol
    private let logger: Logger

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
            return .init(dataUpdated: false,
                         invitesChanged: false,
                         planChanged: false,
                         fullRefreshNeeded: true)
        }
        var dataUpdated = false
        var invitesChanged = false
        var planChanged = false
        var fullRefreshNeeded = false
        try await recursivelySync(userId: userId,
                                  lastEventId: lastEventId,
                                  dataUpdated: &dataUpdated,
                                  invitesChanged: &invitesChanged,
                                  planChanged: &planChanged,
                                  fullRefreshNeeded: &fullRefreshNeeded)
        logger.info("Finished syncing with user events for user \(userId)")
        return .init(dataUpdated: dataUpdated,
                     invitesChanged: invitesChanged,
                     planChanged: planChanged,
                     fullRefreshNeeded: fullRefreshNeeded)
    }
}

private extension UserEventsSynchronizer {
    // swiftlint:disable:next function_parameter_count
    func recursivelySync(userId: String,
                         lastEventId: String,
                         dataUpdated: inout Bool,
                         invitesChanged: inout Bool,
                         planChanged: inout Bool,
                         fullRefreshNeeded: inout Bool) async throws {
        logger.trace("Getting user events for user \(userId)")
        let events = try await remoteUserEventsDatasource.getUserEvents(userId: userId,
                                                                        lastEventId: lastEventId)
        logger.trace("Processing events for user \(userId)")
        try await process(events: events, for: userId)
        logger.trace("Processed events for user \(userId)")

        dataUpdated = dataUpdated || events.dataUpdated
        invitesChanged = invitesChanged || events.invitesChanged != nil
        planChanged = planChanged || events.planChanged
        fullRefreshNeeded = fullRefreshNeeded || events.fullRefresh

        logger.trace("Upserting last user event ID for user \(userId)")
        try await localUserEventIdDatasource.upsertLastEventId(userId: userId,
                                                               lastEventId: events.lastEventID)

        if events.eventsPending {
            logger.trace("Continue syncing because events are still pending for user \(userId)")
            return try await recursivelySync(userId: userId,
                                             lastEventId: events.lastEventID,
                                             dataUpdated: &dataUpdated,
                                             invitesChanged: &invitesChanged,
                                             planChanged: &planChanged,
                                             fullRefreshNeeded: &fullRefreshNeeded)
        }
    }

    func process(events: UserEvents, for userId: String) async throws {
        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processUpdatedItems(events.itemsUpdated, userId: userId)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processDeletedItems(events.itemsDeleted, userId: userId)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processAliasNoteChangedItems(events.aliasNoteChanged, userId: userId)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processUpdatedShares(events.sharesUpdated, userId: userId)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processDeletedShares(events.sharesDeleted, userId: userId)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return }
                try await processInviteChanges(inviteChanges: events.invitesChanged,
                                               userId: userId)
            }

            try await taskGroup.waitForAll()
        }
    }

    func processUpdatedItems(_ updatedItems: [UserEventItem], userId: String) async throws {
        guard !updatedItems.isEmpty else {
            logger.trace("No updated items for user \(userId)")
            return
        }
        logger.trace("Refreshing \(updatedItems.count) updated items for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else { return }
            for updatedItem in updatedItems {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await itemRepository.refreshItem(userId: userId,
                                                         shareId: updatedItem.shareID,
                                                         itemId: updatedItem.itemID,
                                                         eventToken: updatedItem.eventToken)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processDeletedItems(_ deletedItems: [UserEventItem], userId: String) async throws {
        guard !deletedItems.isEmpty else {
            logger.trace("No deleted items for user \(userId)")
            return
        }
        logger.trace("Deleting \(deletedItems.count) items for user \(userId)")
        try await itemRepository.delete(userId: userId, items: deletedItems)
    }

    func processAliasNoteChangedItems(_ aliasNoteChangedItems: [UserEventItem],
                                      userId: String) async throws {
        guard !aliasNoteChangedItems.isEmpty else {
            logger.trace("No alias note changed for user \(userId)")
            return
        }
        logger.trace("Syncing SL note for \(aliasNoteChangedItems.count) items for user \(userId)")
        _ = try await simpleLoginNoteSynchronizer.syncAliases(userId: userId,
                                                              aliases: aliasNoteChangedItems)
    }

    func processUpdatedShares(_ updatedShares: [UserEventShare], userId: String) async throws {
        guard !updatedShares.isEmpty else {
            logger.trace("No updated shares for user \(userId)")
            return
        }
        logger.trace("Refreshing \(updatedShares.count) shares for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else { return }
            for updatedShare in updatedShares {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await shareRepository.refreshShare(userId: userId,
                                                           shareId: updatedShare.shareID,
                                                           eventToken: updatedShare.eventToken)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processDeletedShares(_ deletedShares: [UserEventShare], userId: String) async throws {
        guard !deletedShares.isEmpty else {
            logger.trace("No deleted shares for user \(userId)")
            return
        }
        logger.trace("Deleting \(deletedShares.count) shares for user \(userId)")
        try await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else { return }
            for deletedShare in deletedShares {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await shareRepository.deleteShareLocally(userId: userId,
                                                                 shareId: deletedShare.shareID)
                    try await itemRepository.deleteAllItemsLocally(shareId: deletedShare.shareID)
                }
            }

            try await taskGroup.waitForAll()
        }
    }

    func processInviteChanges(inviteChanges: UserEventInviteChange?,
                              userId: String) async throws {
        guard inviteChanges != nil else {
            logger.trace("No invite changes for user \(userId)")
            return
        }
        try await inviteRepository.refreshInvites(userId: userId)
    }
}
