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

import Client
import ClientMocks
import Core
import CoreMocks
import Testing
import TestingToolkit

@Suite(.tags(.synchronizer))
struct UserEventsSynchronizerTests {
    let localUserEventIdDatasource = LocalUserEventIdDatasourceProtocolMock()
    let remoteUserEventsDatasource = RemoteUserEventsDatasourceProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()
    let shareRepository = ShareRepositoryProtocolMock()
    let accessRespository = AccessRepositoryProtocolMock()
    var sut: (any UserEventsSynchronizerProtocol)!

    init() {
        sut = UserEventsSynchronizer(localUserEventIdDatasource: localUserEventIdDatasource,
                                     remoteUserEventsDatasource: remoteUserEventsDatasource,
                                     itemRepository: itemRepository,
                                     shareRepository: shareRepository,
                                     accessRepository: accessRespository,
                                     logManager: LogManagerProtocolMock())
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
    var storedLastEventId: String?

    static var noLocalLastEventIdTriggerFullRefresh: Self {
        .init(result: .init(dataUpdated: false,
                            planChanged: false,
                            fullRefreshNeeded: true),
              getUserEventsRouteCalled: false)
    }

    static var fullRefresh: Self {
        .init(lastEventId: .random(),
              events: [
                .init(lastEventID: .random(),
                      itemsUpdated: [],
                      itemsDeleted: [],
                      sharesUpdated: [],
                      sharesDeleted: [],
                      sharesToGetInvites: [],
                      sharesWithInvitesToCreate: [],
                      planChanged: false,
                      eventsPending: false,
                      fullRefresh: true)
              ],
              result: .init(dataUpdated: false,
                            planChanged: false,
                            fullRefreshNeeded: true),
              getUserEventsRouteCalled: true)
    }

    static var oneEventBatch: Self {
        .init(lastEventId: .random(),
              events: [
                .init(lastEventID: "TestID",
                      itemsUpdated: .random(count: 5),
                      itemsDeleted: .random(count: 8),
                      sharesUpdated: .random(count: 19),
                      sharesDeleted: .random(count: 21),
                      sharesToGetInvites: [],
                      sharesWithInvitesToCreate: [],
                      planChanged: false,
                      eventsPending: false,
                      fullRefresh: false)
              ],
              result: .init(dataUpdated: true,
                            planChanged: false,
                            fullRefreshNeeded: false),
              getUserEventsRouteCalled: true,
              refreshItemInvokeCount: 5,
              deleteItemsInvokeCount: 1,
              refreshShareInvokeCount: 19,
              deleteShareInvokeCount: 21,
              storedLastEventId: "TestID")
    }

    static var twoEventBatches: Self {
        .init(lastEventId: .random(),
              events: [
                .init(lastEventID: "TestID1",
                      itemsUpdated: .random(count: 7),
                      itemsDeleted: .random(count: 16),
                      sharesUpdated: .random(count: 3),
                      sharesDeleted: .random(count: 8),
                      sharesToGetInvites: [],
                      sharesWithInvitesToCreate: [],
                      planChanged: true,
                      eventsPending: true,
                      fullRefresh: false),
                .init(lastEventID: "TestID2",
                      itemsUpdated: .random(count: 10),
                      itemsDeleted: .random(count: 3),
                      sharesUpdated: .random(count: 27),
                      sharesDeleted: .random(count: 14),
                      sharesToGetInvites: [],
                      sharesWithInvitesToCreate: [],
                      planChanged: false,
                      eventsPending: false,
                      fullRefresh: false)
              ],
              result: .init(dataUpdated: true,
                            planChanged: true,
                            fullRefreshNeeded: false),
              getUserEventsRouteCalled: true,
              refreshItemInvokeCount: 17,
              deleteItemsInvokeCount: 2,
              refreshShareInvokeCount: 30,
              deleteShareInvokeCount: 22,
              storedLastEventId: "TestID2")
    }
}

private extension UserEventsSynchronizerTests {
    @Test("User events sync",
          arguments: [
            Args.noLocalLastEventIdTriggerFullRefresh,
            Args.fullRefresh,
            Args.oneEventBatch,
            Args.twoEventBatches
          ])
    func sync(args: Args) async throws {
        localUserEventIdDatasource.stubbedGetLastEventIdResult = args.lastEventId

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
            #expect(itemRepository.invokedDeleteCount == deleteItemsInvokeCount)
        }

        if let refreshShareInvokeCount = args.refreshShareInvokeCount {
            #expect(shareRepository.invokedRefreshShareCount == refreshShareInvokeCount)
        }

        if let deleteShareInvokeCount = args.deleteShareInvokeCount {
            #expect(shareRepository.invokedDeleteShareLocallyCount == deleteShareInvokeCount)
        }

        if let storedLastEventId = args.storedLastEventId {
            #expect(localUserEventIdDatasource.invokedUpsertLastEventIdParameters?.lastEventId ==
                    storedLastEventId)
        }
    }
}

extension UserEventItem: Randomable {
    public static func random() -> Self {
        .init(shareID: .random(), itemID: .random(), eventToken: .random())
    }
}

extension UserEventShare: Randomable {
    public static func random() -> Self {
        .init(shareID: .random(),  eventToken: .random())
    }
}
