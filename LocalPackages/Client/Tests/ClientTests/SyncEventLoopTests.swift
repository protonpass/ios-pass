//
// SyncEventLoopTests.swift
// Proton Pass - Created on 13/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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
@preconcurrency import Combine
import Core
import CoreMocks
import Network
import ProtonCoreLogin
import Testing

@Suite(.timeLimit(.minutes(1)), .tags(.synchronizer))
struct SyncEventLoopTests {
    private let user = UserData.random()
    private let userEventsSynchronizer = UserEventsSynchronizerSpy()

    @Test func `A full sync in progress skips the loop and stops pull to refresh`() async {
        let events = await runLoop(isFullSyncing: true, untilEventCount: 2)

        #expect(events == [.stoppedRefreshing, .skippedForFullSync])
        #expect(await userEventsSynchronizer.syncedUserIds.isEmpty)
    }

    @Test func `Without a full sync in progress every account is synced`() async {
        let events = await runLoop(isFullSyncing: false, untilEventCount: 2)

        #expect(events == [.began(userId: user.user.ID), .finished(userId: user.user.ID)])
        #expect(await userEventsSynchronizer.syncedUserIds == [user.user.ID])
    }
}

private extension SyncEventLoopTests {
    func runLoop(isFullSyncing: Bool, untilEventCount count: Int) async -> [SyncEventLoopDelegateFake.Event] {
        let userManager = UserManagerProtocolMock()
        userManager.stubbedAllUserAccounts = .init([user])
        let delegate = SyncEventLoopDelegateFake(isFullSyncing: isFullSyncing)
        let loop = SyncEventLoop(currentDateProvider: CurrentDateProvider(),
                                 userEventsSynchronizer: userEventsSynchronizer,
                                 coreEventsSynchronizer: CoreEventsSynchronizerStub(),
                                 userManager: userManager,
                                 logManager: LogManagerProtocolMock(),
                                 reachability: ReachabilityStub())
        loop.delegate = delegate
        loop.pullToRefreshDelegate = delegate

        loop.forceSync()
        let events = await delegate.events(count: count)
        // The loop's tasks capture it weakly, it must outlive them
        withExtendedLifetime(loop) {}
        return events
    }
}

private final class SyncEventLoopDelegateFake: SyncEventLoopDelegate, SyncEventLoopPullToRefreshDelegate {
    enum Event: Equatable {
        case began(userId: String)
        case finished(userId: String)
        case failed(userId: String)
        case skippedForFullSync
        case skippedForOtherReason
        case stoppedRefreshing
    }

    private let isFullSyncing: Bool
    private let stream: AsyncStream<Event>
    private let continuation: AsyncStream<Event>.Continuation

    init(isFullSyncing: Bool) {
        self.isFullSyncing = isFullSyncing
        (stream, continuation) = AsyncStream.makeStream()
    }

    func events(count: Int) async -> [Event] {
        var events: [Event] = []
        for await event in stream.prefix(count) {
            events.append(event)
        }
        return events
    }

    func syncEventLoopDidStartLooping() {}

    func syncEventLoopDidStopLooping() {}

    func syncEventLoopDidBeginNewLoop(userId: String) {
        continuation.yield(.began(userId: userId))
    }

    func syncEventLoopIsFullSyncing() async -> Bool {
        isFullSyncing
    }

    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason) {
        if case .fullSyncInProgress = reason {
            continuation.yield(.skippedForFullSync)
        } else {
            continuation.yield(.skippedForOtherReason)
        }
    }

    func syncEventLoopRequiresFullSync(userId: String) async throws {}

    func syncEventLoopDidFinishLoop(userId: String, hasNewEvents: Bool) {
        continuation.yield(.finished(userId: userId))
    }

    func syncEventLoopDidFailLoop(userId: String, error: any Error) {
        continuation.yield(.failed(userId: userId))
    }

    func pullToRefreshShouldStopRefreshing() {
        continuation.yield(.stoppedRefreshing)
    }
}

private actor UserEventsSynchronizerSpy: UserEventsSynchronizerProtocol {
    private(set) var syncedUserIds: [String] = []

    func sync(userId: String, readOnly: Bool) async throws -> UserEventsSyncResult {
        syncedUserIds.append(userId)
        return []
    }
}

private struct CoreEventsSynchronizerStub: CoreEventsSynchronizerProtocol {
    func sync(userId: String) async throws {}
}

private final class ReachabilityStub: ReachabilityServicing {
    let reachabilityInfos = CurrentValueSubject<NWPath?, Never>(nil)
    let isNetworkAvailable = CurrentValueSubject<Bool, Never>(true)
    let typeOfCurrentConnection = CurrentValueSubject<NerworkType, Never>(.wifi)
}
