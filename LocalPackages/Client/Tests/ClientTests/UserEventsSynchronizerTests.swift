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
import Testing

struct UserEventsSynchronizerTests {
    var localUserEventIdDatasource: LocalUserEventIdDatasourceProtocolMock!
    var remoteUserEventsDatasource: RemoteUserEventsDatasourceProtocolMock!
    var itemRepository: ItemRepositoryProtocolMock!
    var accessRespository: AccessRepositoryProtocolMock!
    var sut: UserEventsSynchronizerProtocol!

    init() {
        localUserEventIdDatasource = .init()
        remoteUserEventsDatasource = .init()
        itemRepository = .init()
        accessRespository = .init()
        sut = UserEventsSynchronizer(localUserEventIdDatasource: localUserEventIdDatasource,
                               remoteUserEventsDatasource: remoteUserEventsDatasource,
                               itemRepository: itemRepository,
                               accessRepository: accessRespository)
    }
}

private struct Args {
    var lastEventId: String?
    var events: [UserEvents]?
    let result: UserEventsSyncResult
    let getUserEventsRouteCalled: Bool
    var refreshItemInvokeCount: Int?
    var deleteItemInvokeCount: Int?

    static var noLocalLastEventIdTriggerFullRefresh: Self {
        .init(result: .init(dataUpdated: false,
                            planChanged: false,
                            fullRefreshNeeded: true),
              getUserEventsRouteCalled: false)
    }
}

private extension UserEventsSynchronizerTests {
    @Test("User events sync",
          arguments: [
            Args.noLocalLastEventIdTriggerFullRefresh
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

        if let deleteItemInvokeCount = args.deleteItemInvokeCount {
            #expect(itemRepository.invokedDeleteItemsCount == deleteItemInvokeCount)
        }
    }
}

private extension UserEventItem {
    static func random() -> UserEventItem {
        UserEventItem(shareID: .random(), itemID: .random(), eventToken: .random())
    }
}

private extension [UserEventItem] {
    static func random(count: Int) {
        Array(repeating: UserEventItem.random(), count: count)
    }
}

private extension UserEventShare {
    static func random() -> UserEventShare {
        UserEventShare(shareID: .random(), eventToken: .random())
    }
}
