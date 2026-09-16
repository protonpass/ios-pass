//
// UserEventsSynchronizerTests.swift
// Proton Pass - Created on 19/05/2025.
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
//

@testable import Client
import ClientMocks
import Core
import CoreMocks
import Testing
import TestingToolkit
import Entities

@Suite(.serialized, .tags(.synchronizer))
@MainActor
struct UserEventsSynchronizerTests {
    let localItemDatasource = LocalItemDatasourceProtocolMock()
    let localUserEventIdDatasource = LocalUserEventIdDatasourceProtocolMock()
    let remoteUserEventsDatasource = RemoteUserEventsDatasourceProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()
    let shareRepository = ShareRepositoryProtocolMock()
    let accessRespository = AccessRepositoryProtocolMock()
    let inviteRepository = FullInviteRepositoryProtocolMock()
    let slNoteSynchronizer = SimpleLoginNoteSynchronizerProtocolMock()
    let aliasRepository = AliasRepositoryProtocolMock()
    let passMonitorRepository = PassMonitorRepositoryProtocolMock()
    let organizationRepository = OrganizationRepositoryProtocolMock()
    let folderRepositoryProtocolMock = FolderRepositoryProtocolMock()

    var sut: (any UserEventsSynchronizerProtocol)!

    init() {
        accessRespository.stubbedRefreshAccessResult = .init(userId: "UserId", access: .init(plan: .mockFreePlan,
                                                                                         monitor: .mock(),
                                                                                         pendingInvites: 0,
                                                                                         waitingNewUserInvites: 0,
                                                                                         minVersionUpgrade: nil,
                                                                                         userData: .mock(aliasSyncEnabled: true,
                                                                                                         pendingAliasToSync: 10)) )
        
        
        sut = UserEventsSynchronizer(localUserEventIdDatasource: localUserEventIdDatasource,
                                     remoteUserEventsDatasource: remoteUserEventsDatasource,
                                     itemRepository: itemRepository,
                                     shareRepository: shareRepository,
                                     accessRepository: accessRespository,
                                     inviteRepository: inviteRepository,
                                     folderRepository: folderRepositoryProtocolMock,
                                     aliasRepository: aliasRepository,
                                     passMonitorRepository: passMonitorRepository,
                                     organizationRepository: organizationRepository,
                                     simpleLoginNoteSynchronizer: slNoteSynchronizer,
                                     logManager: LogManagerProtocolMock())
       
    }
}

private extension UserEvents {
    static func make(lastEventID: String,
                     itemsUpdated: [ItemEvent] = [],
                     itemsDeleted: [ItemEvent] = [],
                     aliasNoteChanged: [ItemEvent] = [],
                     invitesChanged: ChangeEvent? = nil,
                     sharesCreated: [ShareEvent] = [],
                     sharesUpdated: [ShareEvent] = [],
                     sharesDeleted: [ShareEvent] = [],
                     refreshUser: Bool = false,
                     eventsPending: Bool = false,
                     fullRefresh: Bool = false) -> Self {
        .init(lastEventID: lastEventID,
              itemsUpdated: itemsUpdated,
              itemsDeleted: itemsDeleted,
              aliasNoteChanged: aliasNoteChanged,
              invitesChanged: invitesChanged,
              groupInvitesChanged: nil,
              sharesCreated: sharesCreated,
              sharesUpdated: sharesUpdated,
              sharesDeleted: sharesDeleted,
              sharesWithInvitesToCreate: [],
              foldersUpdated: [],
              foldersDeleted: [],
              pendingAliasToCreateChanged: nil,
              breachUpdate: nil,
              organizationUpdate: nil,
              refreshUser: refreshUser,
              eventsPending: eventsPending,
              fullRefresh: fullRefresh)
    }
}

private struct Args {
    var lastEventId: String?
    var events: [UserEvents]?
    let result: UserEventsSyncResult
    let getUserEventsRouteCalled: Bool
    var refreshItemInvokeCount: Int?
    var deleteItemsInvokeCount: Int?
    var refreshShareInvokeCount: Int?
    var deleteShareInvokeCount: Int?
    var refreshInviteInvokeCount: Int?
    var syncSimpleLoginNoteInvokeCount: Int?
    var storedLastEventId: String?
    /// Type of the share returned by the stubbed `refreshShare`
    var refreshedShareType: TargetType = .vault
    var refreshFoldersInvokeCount: Int?
    var refreshItemsInvokeCount: Int?

    static var noLocalLastEventIdTriggerFullRefresh: Self {
        .init(result: [.fullRefreshNeeded],
              getUserEventsRouteCalled: false)
    }

    static var fullRefresh: Self {
        .init(lastEventId: .random(),
              events: [.make(lastEventID: .random(), fullRefresh: true)],
              result: [.fullRefreshNeeded],
              getUserEventsRouteCalled: true)
    }

    static var oneEventBatch: Self {
        .init(lastEventId: .random(),
              events: [
                  .make(lastEventID: "TestID",
                        itemsUpdated: .random(count: 5),
                        itemsDeleted: .random(count: 8),
                        aliasNoteChanged: .random(count: 14),
                        sharesUpdated: .random(count: 19),
                        sharesDeleted: .random(count: 21))
              ],
              result: [.dataUpdated],
              getUserEventsRouteCalled: true,
              refreshItemInvokeCount: 5,
              deleteItemsInvokeCount: 1,
              refreshShareInvokeCount: 19,
              deleteShareInvokeCount: 21,
              syncSimpleLoginNoteInvokeCount: 1,
              storedLastEventId: "TestID")
    }

    static var twoEventBatches: Self {
        .init(lastEventId: .random(),
              events: [
                  .make(lastEventID: "TestID1",
                        itemsUpdated: .random(count: 7),
                        itemsDeleted: .random(count: 16),
                        aliasNoteChanged: .random(count: 90),
                        sharesUpdated: .random(count: 3),
                        sharesDeleted: .random(count: 8),
                        refreshUser: true,
                        eventsPending: true),
                  .make(lastEventID: "TestID2",
                        itemsUpdated: .random(count: 10),
                        itemsDeleted: .random(count: 3),
                        aliasNoteChanged: .random(count: 3),
                        invitesChanged: .init(eventToken: .random()),
                        sharesUpdated: .random(count: 27),
                        sharesDeleted: .random(count: 14))
              ],
              result: [.dataUpdated, .invitesChanged, .refreshUser],
              getUserEventsRouteCalled: true,
              refreshItemInvokeCount: 17,
              deleteItemsInvokeCount: 2,
              refreshShareInvokeCount: 30,
              deleteShareInvokeCount: 22,
              refreshInviteInvokeCount: 1,
              syncSimpleLoginNoteInvokeCount: 2,
              storedLastEventId: "TestID2")
    }

    static var createdVaultShare: Self {
        createdShare(type: .vault, refreshFoldersInvokeCount: 1)
    }

    /// Item shares have no folders, the endpoint answers 403 for them
    static var createdItemShare: Self {
        createdShare(type: .item, refreshFoldersInvokeCount: 0)
    }

    private static func createdShare(type: TargetType, refreshFoldersInvokeCount: Int) -> Self {
        .init(lastEventId: .random(),
              events: [.make(lastEventID: "CreatedShareID", sharesCreated: .random(count: 1))],
              result: [.dataUpdated],
              getUserEventsRouteCalled: true,
              refreshShareInvokeCount: 1,
              deleteShareInvokeCount: 0,
              storedLastEventId: "CreatedShareID",
              refreshedShareType: type,
              refreshFoldersInvokeCount: refreshFoldersInvokeCount,
              refreshItemsInvokeCount: 1)
    }
}

private extension UserEventsSynchronizerTests {
    @Test("User events sync",
          arguments: [
            Args.noLocalLastEventIdTriggerFullRefresh,
            Args.fullRefresh,
            Args.oneEventBatch,
            Args.twoEventBatches,
            Args.createdVaultShare,
            Args.createdItemShare
          ])
    func sync(args: Args) async throws {
        await slNoteSynchronizer.stubResults()
        localUserEventIdDatasource.stubbedGetLastEventIdResult = args.lastEventId
        shareRepository.stubbedRefreshShareResult = .random(targetType: args.refreshedShareType)

        if var events = args.events {
            remoteUserEventsDatasource.closureGetUserEvents = {
                remoteUserEventsDatasource.stubbedGetUserEventsResult = events.removeFirst()
            }
        }

        let result = try await sut.sync(userId: .random())
        #expect(result == args.result)

        #expect(remoteUserEventsDatasource.invokedGetUserEventsfunction ==
                args.getUserEventsRouteCalled)

        if let refreshItemInvokeCount = args.refreshItemInvokeCount {
            #expect(itemRepository.invokedRefreshItemCount == refreshItemInvokeCount)
        }

        if let deleteItemsInvokeCount = args.deleteItemsInvokeCount {
            #expect(itemRepository.invokedDeleteItemsLocallyItemsAsyncCount34 == deleteItemsInvokeCount)
        }

        if let refreshShareInvokeCount = args.refreshShareInvokeCount {
            await #expect(shareRepository.invokedRefreshShareCount == refreshShareInvokeCount)
        }

        if let deleteShareInvokeCount = args.deleteShareInvokeCount {
            await #expect(shareRepository.invokedDeleteShareLocallyCount == deleteShareInvokeCount)
        }

        if let refreshInviteInvokeCount = args.refreshInviteInvokeCount {
            #expect(inviteRepository.invokedRefreshSpecificInvitesCount == refreshInviteInvokeCount)
        }

        if let syncSimpleLoginNoteInvokeCount = args.syncSimpleLoginNoteInvokeCount {
            await #expect(slNoteSynchronizer.invokedSyncAliasesCount == syncSimpleLoginNoteInvokeCount)
        }

        if let storedLastEventId = args.storedLastEventId {
            #expect(localUserEventIdDatasource.invokedUpsertLastEventIdParameters?.lastEventId ==
                    storedLastEventId)
        }

        if let refreshFoldersInvokeCount = args.refreshFoldersInvokeCount {
            #expect(folderRepositoryProtocolMock.invokedRefreshFoldersUserIdShareIdAsyncCount5 ==
                    refreshFoldersInvokeCount)
        }

        if let refreshItemsInvokeCount = args.refreshItemsInvokeCount {
            #expect(itemRepository.invokedRefreshItemsCount == refreshItemsInvokeCount)
        }
    }

    /// A failing folder refresh must not advance the event cursor, otherwise the batch is skipped and the
    /// local data it describes is never reconciled.
    @Test("Failing to refresh the folders of a created share does not advance the last event ID")
    func failedFolderRefreshKeepsLastEventId() async throws {
        await slNoteSynchronizer.stubResults()
        localUserEventIdDatasource.stubbedGetLastEventIdResult = .random()
        shareRepository.stubbedRefreshShareResult = .random(targetType: .vault)
        folderRepositoryProtocolMock.refreshFoldersUserIdShareIdThrowableError5 = PassError.unexpectedError

        remoteUserEventsDatasource.stubbedGetUserEventsResult =
            .make(lastEventID: "NeverStored", sharesCreated: .random(count: 1))

        await #expect(throws: (any Error).self) {
            try await sut.sync(userId: .random())
        }
        #expect(!localUserEventIdDatasource.invokedUpsertLastEventIdfunction)
    }
}

extension ItemEvent: Randomable {
    public static func random() -> Self {
        .init(shareID: .random(), itemID: .random(), eventToken: .random())
    }
}

extension ShareEvent: Randomable {
    public static func random() -> Self {
        .init(shareID: .random(),  eventToken: .random())
    }
}

private extension SimpleLoginNoteSynchronizerProtocolMock {
    func stubResults() async {
        stubbedSyncAllAliasesResult = true
        stubbedSyncAliasesResult = true
    }
}
