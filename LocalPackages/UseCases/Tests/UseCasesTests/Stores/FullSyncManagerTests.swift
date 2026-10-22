//
// FullSyncManagerTests.swift
// Proton Pass - Created on 21/10/2026.
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

@testable import Stores
import Client
import ClientMocks
import Core
import CoreMocks
import Entities
import EntitiesMocks
import Foundation
import Testing
import UseCases

@Suite(.serialized, .timeLimit(.minutes(1)), .tags(.store))
@MainActor
struct FullSyncManagerTests {
    private let refresh = RefreshUserDataFake()
    private let deleteLocalData = DeleteLocalDataSpy()
    private let lastEventId = LastEventIdSpy()
    private let aliasSynchronizer = AliasSynchronizerFake()
    private let contentDelegate = ContentDelegateSpy()
    private let shareRepository = ShareRepositoryProtocolMock()
    private let syncEventLoop = SyncEventLoopProtocolMock()
    private let sut: FullSyncManager

    init() {
        kSharedUserDefaults.removeObject(forKey: Constants.incompleteFullSyncUserId)
        kSharedUserDefaults.removeObject(forKey: Constants.incompleteFullSyncUserIds)
        shareRepository.stubbedGetDecryptedRemoteSharesResult = .init(shares: [], hasUndecryptableShares: false)
        shareRepository.stubbedCreateVaultResult = .random()
        sut = FullSyncManager(itemRepository: ItemRepositoryProtocolMock(),
                              shareRepository: shareRepository,
                              inviteRepository: FullInviteRepositoryProtocolMock(),
                              folderRepository: FolderRepositoryProtocolMock(),
                              slNoteSynchronizer: aliasSynchronizer,
                              refreshUserData: refresh,
                              deleteLocalDataBeforeFullSync: deleteLocalData,
                              getAndStoreLastEventId: lastEventId,
                              logger: Logger(manager: LogManagerProtocolMock()),
                              fullSyncStallTimeout: .seconds(1))
        sut.contentDelegate = contentDelegate
    }

    @Test func `A finished sync keeps reporting its outcome to late observers`() async {
        refresh.failingUserIds = ["user-a"]

        let operation = sut.start(userId: "user-a", presentation: .sheet)
        _ = await operation.result()

        #expect(await operation.result().error != nil, "Late observer must still see the failure")
        #expect(sut.fullSyncOperation === operation)
        #expect(!sut.hasFullSyncTask(userId: "user-a"))
    }

    @Test(arguments: [true, false])
    func `Only a sync that got as far as the wipe marks the account interrupted`(failsAfterWipe: Bool) async {
        if failsAfterWipe {
            deleteLocalData.failingUserIds = ["user-a"]
        } else {
            refresh.failingUserIds = ["user-a"]
        }

        _ = await sut.start(userId: "user-a", presentation: .sheet).result()

        #expect(sut.incompleteFullSyncUserIds == (failsAfterWipe ? ["user-a"] : []))
    }

    @Test func `A completed sync reports the progress of each vault`() async {
        let vault = Share.random(targetType: 1)
        shareRepository.stubbedGetDecryptedRemoteSharesResult = .init(shares: [vault],
                                                                      hasUndecryptableShares: true)

        let operation = sut.start(userId: "user-a", presentation: .sheet)
        let outcome = await operation.result()

        #expect(outcome.hasUndecryptableShares == true)
        #expect(operation.progresses.map(\.shareId) == [vault.shareID])
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
    }

    @Test func `The content is loaded last, once the last event ID is stored`() async {
        var storedEventIdsWhenLoading: [String]?
        contentDelegate.onLoad = { storedEventIdsWhenLoading = lastEventId.storedUserIds }

        #expect(await sut.start(userId: "user-a", presentation: .sheet).result().isCompleted)

        #expect(storedEventIdsWhenLoading == ["user-a"])
        #expect(contentDelegate.loadedUserIds == ["user-a"])
    }

    @Test func `A sync failing before its last step loads no content`() async {
        lastEventId.failingUserIds = ["user-a"]

        #expect(await sut.start(userId: "user-a", presentation: .sheet).result().error != nil)

        #expect(contentDelegate.loadedUserIds.isEmpty)
        #expect(sut.incompleteFullSyncUserIds == ["user-a"])
    }

    @Test func `Concurrent requests for the same user share one sync`() async {
        let gate = refresh.pause("user-a")

        let first = sut.start(userId: "user-a", presentation: .sheet)
        await gate.entered.wait()
        let second = sut.start(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await second.result()

        #expect(first === second)
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `A sheet request joins an inline sync in flight without presenting it`() async {
        let gate = refresh.pause("user-a")

        let inline = sut.start(userId: "user-a", presentation: .inline)
        await gate.entered.wait()
        let sheet = sut.start(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await inline.result()

        #expect(inline === sheet)
        #expect(inline.presentation == .inline)
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `Joining a sync publishes it again for observers that skipped it`() async {
        let gate = refresh.pause("user-a")
        let running = sut.start(userId: "user-a", presentation: .inline)
        let queued = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        let joined = sut.start(userId: "user-a", presentation: .sheet)

        #expect(joined === running)
        #expect(sut.fullSyncOperation === running)
        gate.release.open()
        _ = await queued.result()
    }

    @Test func `Syncs for different users run one after the other`() async {
        let gate = refresh.pause("user-a")
        refresh.failingUserIds = ["user-a", "user-b"]

        let first = sut.start(userId: "user-a", presentation: .sheet)
        let second = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()
        #expect(refresh.calls == ["user-a"])

        gate.release.open()
        _ = await second.result()

        #expect(first !== second)
        #expect(second.userId == "user-b")
        #expect(refresh.calls == ["user-a", "user-b"])
        #expect(first.outcome != nil)
        #expect(sut.fullSyncOperation === second)
    }

    @Test func `A sync queued behind another account's counts as in progress for its account`() async {
        let gate = refresh.pause("user-a")
        _ = sut.start(userId: "user-a", presentation: .sheet)
        let queued = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        #expect(sut.isFullSyncing(userId: "user-b"))
        #expect(!sut.isFullSyncing(userId: "user-c"))

        gate.release.open()
        _ = await queued.result()
        #expect(!sut.isFullSyncing(userId: "user-b"))
    }

    @Test func `Retrying after a failure starts a new sync`() async {
        refresh.failingUserIds = ["user-a"]

        let failed = sut.start(userId: "user-a", presentation: .sheet)
        _ = await failed.result()
        let retried = sut.start(userId: "user-a", presentation: .sheet)
        _ = await retried.result()

        #expect(failed !== retried)
        #expect(refresh.calls == ["user-a", "user-a"])
    }

    @Test func `Reset cancels running and queued syncs and waits for them`() async {
        let gate = refresh.pause("user-a")
        let running = sut.start(userId: "user-a", presentation: .sheet)
        let queued = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        let resetRequested = Gate()
        let resetting = Task {
            resetRequested.open()
            await sut.reset()
        }
        await resetRequested.wait()
        #expect(sut.hasFullSyncTask(userId: "user-a"))
        gate.release.open()
        await resetting.value

        #expect(await running.result().isCancelled)
        #expect(await queued.result().isCancelled)
        #expect(refresh.calls == ["user-a"])
        #expect(deleteLocalData.deletedUserIds.isEmpty)
        #expect(!sut.hasFullSyncTask(userId: "user-a"))
        #expect(!sut.hasFullSyncTask(userId: "user-b"))
        #expect(sut.fullSyncOperation == nil)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
    }

    @Test func `A cancelled sync finishing late does not drop the sync started after it`() async {
        let gateA = refresh.pause("user-a")
        let gateC = refresh.pause("user-c")
        _ = sut.start(userId: "user-a", presentation: .sheet)
        await gateA.entered.wait()

        let resetRequested = Gate()
        let resetting = Task {
            resetRequested.open()
            await sut.reset()
        }
        await resetRequested.wait()
        let next = sut.start(userId: "user-c", presentation: .sheet)
        gateA.release.open()
        await resetting.value
        await gateC.entered.wait()

        #expect(sut.hasFullSyncTask(userId: "user-c"))
        gateC.release.open()
        _ = await next.result()
        // The task outlives the operation while alias notes sync, so wait for it to return
        await sut.reset()
        #expect(!sut.hasFullSyncTask(userId: "user-c"), "Each task removes only its own entry")
    }

    @Test func `Logging out an account cancels its sync and clears its marker`() async {
        let gate = refresh.pause("user-b")
        let operation = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        let cancelRequested = Gate()
        let cancelling = Task {
            cancelRequested.open()
            await sut.cancel(userId: "user-b")
        }
        await cancelRequested.wait()
        gate.release.open()
        await cancelling.value

        #expect(await operation.result().isCancelled)
        #expect(deleteLocalData.deletedUserIds.isEmpty)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
        #expect(!sut.hasFullSyncTask(userId: "user-b"))
    }

    @Test func `Logging out an account with a queued sync does not wait for the running one`() async {
        let gate = refresh.pause("user-a")
        let running = sut.start(userId: "user-a", presentation: .sheet)
        let queued = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        await sut.cancel(userId: "user-b")
        #expect(running.outcome == nil)

        gate.release.open()
        #expect(await queued.result().isCancelled)
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `A sync that owns the event loop cancels the running iteration and keeps looping`() async {
        refresh.failingUserIds = ["user-a"]
        let fullContentSync = FullContentSync(syncEventLoop: syncEventLoop, fullSyncManager: sut)

        let operation = fullContentSync(userId: "user-a", presentation: .sheet, shouldStopEventLoop: true)

        #expect(sut.hasFullSyncTask(userId: "user-a"))
        #expect(syncEventLoop.invokedStopCount == 1)
        #expect(syncEventLoop.invokedStartCount == 1)
        _ = await operation.result()
    }

    @Test func `A sync that does not own the event loop leaves it alone`() async {
        refresh.failingUserIds = ["user-a"]
        let fullContentSync = FullContentSync(syncEventLoop: syncEventLoop, fullSyncManager: sut)

        let operation = fullContentSync(userId: "user-a", presentation: .sheet, shouldStopEventLoop: false)
        _ = await operation.result()

        #expect(syncEventLoop.invokedStopCount == 0)
        #expect(syncEventLoop.invokedStartCount == 0)
    }

    @Test func `A sync without progress fails so the user can retry`() async throws {
        let gate = refresh.pause("user-a")

        let stalled = sut.start(userId: "user-a", presentation: .sheet)
        let error = try #require(await stalled.result().error as? URLError)
        #expect(error.code == .timedOut)

        let retried = sut.start(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await retried.result()

        #expect(stalled.outcome?.error is URLError,
                "The stalled task returning later must not replace the failure")
        #expect(retried !== stalled)
        #expect(refresh.calls == ["user-a", "user-a"])
        #expect(deleteLocalData.deletedUserIds == ["user-a"])
    }

    @Test func `Another account completing its sync keeps an interrupted account marked`() async {
        deleteLocalData.failingUserIds = ["user-a"]

        _ = await sut.start(userId: "user-a", presentation: .sheet).result()
        _ = await sut.start(userId: "user-b", presentation: .sheet).result()

        #expect(sut.incompleteFullSyncUserIds == ["user-a"])
    }

    @Test func `An interrupted account marked by an older version is resumed and cleared`() async {
        kSharedUserDefaults.set("user-b", forKey: Constants.incompleteFullSyncUserId)
        #expect(sut.incompleteFullSyncUserIds == ["user-b"])

        _ = await sut.start(userId: "user-b", presentation: .sheet).result()

        #expect(sut.incompleteFullSyncUserIds.isEmpty)
        #expect(kSharedUserDefaults.string(forKey: Constants.incompleteFullSyncUserId) == nil)
    }

    @Test func `Slow steps are not a stall as long as the sync moves on`() async {
        refresh.delay = .milliseconds(600)
        deleteLocalData.delay = .milliseconds(600)

        let operation = sut.start(userId: "user-a", presentation: .sheet)

        #expect(await operation.result().isCompleted, "Each step is under the stall timeout")
    }

    @Test func `A sync finishes without waiting for the alias notes`() async {
        let aliasNotes = Gate()
        await aliasSynchronizer.pause(until: aliasNotes)

        let operation = sut.start(userId: "user-a", presentation: .sheet)

        #expect(await operation.result().isCompleted)
        #expect(sut.hasFullSyncTask(userId: "user-a"), "The event loop must not write the account's items yet")
        #expect(!sut.isFullSyncing(userId: "user-a"), "Switching to the account must not resync it")
        aliasNotes.open()
    }

    @Test func `A sync waiting in the queue skips the alias notes of the one before`() async {
        let gate = refresh.pause("user-a")
        _ = sut.start(userId: "user-a", presentation: .sheet)
        let queued = sut.start(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        gate.release.open()
        _ = await queued.result()
        await sut.reset()

        #expect(await aliasSynchronizer.syncedUserIds == ["user-b"])
    }

    @Test func `A sync queued during the alias notes stops them`() async {
        await aliasSynchronizer.take(.seconds(30))
        _ = await sut.start(userId: "user-a", presentation: .sheet).result()

        let queued = sut.start(userId: "user-a", presentation: .sheet)
        let start = ContinuousClock.now
        #expect(await queued.result().isCompleted)

        #expect(ContinuousClock.now - start < .seconds(10), "The notes must not hold the next sync back")
        await sut.reset()
    }
}

private enum FullSyncTestError: Error {
    case offline
}

private extension FullSyncOperation.Outcome {
    var isCancelled: Bool {
        if case .cancelled = self {
            true
        } else {
            false
        }
    }

    var error: (any Error)? {
        if case let .failed(error) = self {
            error
        } else {
            nil
        }
    }

    var hasUndecryptableShares: Bool? {
        if case let .completed(hasUndecryptableShares) = self {
            hasUndecryptableShares
        } else {
            nil
        }
    }
}

@MainActor
private final class RefreshUserDataFake: RefreshUserDataUseCase {
    private(set) var calls: [String] = []
    var failingUserIds: Set<String> = []
    var error: any Error = FullSyncTestError.offline
    var delay: Duration?
    private var gates: [String: (entered: Gate, release: Gate)] = [:]

    func pause(_ userId: String) -> (entered: Gate, release: Gate) {
        let gate = (entered: Gate(), release: Gate())
        gates[userId] = gate
        return gate
    }

    nonisolated func callAsFunction(userId: String) async throws {
        try await refresh(userId: userId)
    }

    private func refresh(userId: String) async throws {
        calls.append(userId)
        if let delay {
            try await Task.sleep(for: delay)
        }
        if let gate = gates[userId] {
            gate.entered.open()
            await gate.release.wait()
        }
        if failingUserIds.contains(userId) {
            throw error
        }
    }
}

@MainActor
final class Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen {
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume() }
    }
}

@MainActor
private final class DeleteLocalDataSpy: DeleteLocalDataBeforeFullSyncUseCase {
    private(set) var deletedUserIds: [String] = []
    var failingUserIds: Set<String> = []
    var delay: Duration?

    nonisolated func execute(userId: String) async throws {
        try await record(userId)
    }

    private func record(_ userId: String) async throws {
        deletedUserIds.append(userId)
        if let delay {
            try await Task.sleep(for: delay)
        }
        if failingUserIds.contains(userId) {
            throw FullSyncTestError.offline
        }
    }
}

private actor AliasSynchronizerFake: SimpleLoginNoteSynchronizerProtocol {
    private(set) var syncedUserIds: [String] = []
    private var gate: Gate?
    private var duration: Duration?

    func pause(until gate: Gate) {
        self.gate = gate
    }

    /// Unlike `pause(until:)`, stops early when cancelled, like requests that honour cancellation
    func take(_ duration: Duration) {
        self.duration = duration
    }

    func syncAllAliases(userId: String) async throws -> Bool {
        syncedUserIds.append(userId)
        await gate?.wait()
        if let duration {
            try await Task.sleep(for: duration)
        }
        return false
    }

    func syncAliases(userId: String, aliases: [any ItemIdentifiable]) async throws -> Bool {
        false
    }
}

@MainActor
private final class LastEventIdSpy: GetAndStoreLastEventIdUseCase {
    private(set) var storedUserIds: [String] = []
    var failingUserIds: Set<String> = []

    nonisolated func callAsFunction(userId: String) async throws {
        try await store(userId)
    }

    private func store(_ userId: String) throws {
        if failingUserIds.contains(userId) {
            throw FullSyncTestError.offline
        }
        storedUserIds.append(userId)
    }
}

@MainActor
private final class ContentDelegateSpy: FullSyncContentDelegate {
    private(set) var loadedUserIds: [String] = []
    var onLoad: (() -> Void)?

    func fullSyncDidStoreContent(userId: String) async throws {
        onLoad?()
        loadedUserIds.append(userId)
    }
}
