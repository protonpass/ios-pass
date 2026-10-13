//
// AppContentManagerFullSyncTests.swift
// Proton Pass - Created on 23/09/2026.
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
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import ProtonCoreLogin
import Testing
import UseCases
import UseCasesMocks

@Suite(.serialized, .timeLimit(.minutes(1)), .tags(.store))
@MainActor
struct AppContentManagerFullSyncTests {
    private let refresh = RefreshUserDataFake()
    private let deleteLocalData = DeleteLocalDataSpy()
    private let aliasSynchronizer = AliasSynchronizerFake()
    private let indexAllLoginItems = IndexAllLoginItemsSpy()
    private let itemRepository = ItemRepositoryProtocolMock()
    private let shareRepository = ShareRepositoryProtocolMock()
    private let folderRepository = FolderRepositoryProtocolMock()
    private let symmetricKeyProvider = GatedSymmetricKeyProvider()
    private let syncEventLoop = SyncEventLoopProtocolMock()
    private let activeUser = UserData.random()
    private let currentActiveUser: CurrentValueSubject<UserData?, Never>
    private let sut: AppContentManager

    init() {
        currentActiveUser = .init(activeUser)
        kSharedUserDefaults.removeObject(forKey: Constants.incompleteFullSyncUserId)
        kSharedUserDefaults.removeObject(forKey: Constants.incompleteFullSyncUserIds)
        shareRepository.stubbedGetDecryptedRemoteSharesResult = .init(shares: [], hasUndecryptableShares: false)
        shareRepository.stubbedCreateVaultResult = .random()
        shareRepository.stubbedGetDecryptedSharesResult = []
        itemRepository.stubbedGetAllItemsResult = []
        folderRepository.stubbedGetAllLocalFoldersResult = []
        let userManager = UserManagerProtocolMock()
        userManager.stubbedCurrentActiveUser = currentActiveUser
        let logManager = LogManagerProtocolMock()
        let preferences = PreferencesManager(userManager: userManager,
                                             appPreferencesDatasource: LocalAppPreferencesDatasourceProtocolMock(),
                                             sharedPreferencesDatasource: LocalSharedPreferencesDatasourceProtocolMock(),
                                             userPreferencesDatasource: LocalUserPreferencesDatasourceProtocolMock(),
                                             logManager: logManager)
        sut = AppContentManager(itemRepository: itemRepository,
                                shareRepository: shareRepository,
                                inviteRepository: FullInviteRepositoryProtocolMock(),
                                folderRepository: folderRepository,
                                slNoteSynchronizer: aliasSynchronizer,
                                userManager: userManager,
                                preferencesManager: preferences,
                                symmetricKeyProvider: symmetricKeyProvider,
                                indexAllLoginItems: indexAllLoginItems,
                                indexItemsForSpotlight: SyncWorkStub(),
                                deleteLocalDataBeforeFullSync: deleteLocalData,
                                getAndStoreLastEventId: SyncWorkStub(),
                                dedupShare: SyncWorkStub(),
                                refreshUserData: refresh,
                                processVaultSyncEvent: ProcessVaultSyncEvent(),
                                logger: Logger(manager: logManager),
                                loginMethod: LoginMethodFlow(),
                                fullSyncStallTimeout: .seconds(1))
    }

    @Test func `A finished sync keeps reporting its outcome to late observers`() async {
        refresh.failingUserIds = ["user-a"]

        let operation = sut.startFullSync(userId: "user-a", presentation: .sheet)
        _ = await operation.result()

        guard case .failed = await operation.result() else {
            Issue.record("Late observer must still see the failure")
            return
        }
        #expect(sut.fullSyncOperation === operation)
        #expect(!sut.isFullSyncing)
        #expect(sut.incompleteFullSyncUserIds == ["user-a"])
    }

    @Test func `Concurrent requests for the same user share one sync`() async {
        let gate = refresh.pause("user-a")

        let first = sut.startFullSync(userId: "user-a", presentation: .sheet)
        await gate.entered.wait()
        let second = sut.startFullSync(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await second.result()

        #expect(first === second)
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `A sheet request joins an inline sync in flight without presenting it`() async {
        let gate = refresh.pause("user-a")

        let inline = sut.startFullSync(userId: "user-a", presentation: .inline)
        await gate.entered.wait()
        let sheet = sut.startFullSync(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await inline.result()

        #expect(inline === sheet)
        #expect(inline.presentation == .inline)
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `Syncs for different users run one after the other`() async {
        let gate = refresh.pause("user-a")
        refresh.failingUserIds = ["user-a", "user-b"]

        let first = sut.startFullSync(userId: "user-a", presentation: .sheet)
        let second = sut.startFullSync(userId: "user-b", presentation: .sheet)
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

    @Test func `Retrying after a failure starts a new sync`() async {
        refresh.failingUserIds = ["user-a"]

        let failed = sut.startFullSync(userId: "user-a", presentation: .sheet)
        _ = await failed.result()
        let retried = sut.startFullSync(userId: "user-a", presentation: .sheet)
        _ = await retried.result()

        #expect(failed !== retried)
        #expect(refresh.calls == ["user-a", "user-a"])
    }

    @Test func `Reset cancels running and queued syncs and waits for them`() async {
        let gate = refresh.pause("user-a")
        let running = sut.startFullSync(userId: "user-a", presentation: .sheet)
        let queued = sut.startFullSync(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        let resetRequested = Gate()
        let resetting = Task {
            resetRequested.open()
            await sut.reset()
        }
        await resetRequested.wait()
        #expect(sut.isFullSyncing)
        gate.release.open()
        await resetting.value

        guard case .cancelled = await running.result(), case .cancelled = await queued.result() else {
            Issue.record("Reset must cancel every sync in flight")
            return
        }
        #expect(refresh.calls == ["user-a"])
        #expect(deleteLocalData.deletedUserIds.isEmpty)
        #expect(!sut.isFullSyncing)
        #expect(sut.fullSyncOperation == nil)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
    }

    @Test func `A cancelled sync finishing late does not drop the sync started after it`() async {
        let gateA = refresh.pause("user-a")
        let gateC = refresh.pause("user-c")
        _ = sut.startFullSync(userId: "user-a", presentation: .sheet)
        await gateA.entered.wait()

        let resetRequested = Gate()
        let resetting = Task {
            resetRequested.open()
            await sut.reset()
        }
        await resetRequested.wait()
        let next = sut.startFullSync(userId: "user-c", presentation: .sheet)
        gateA.release.open()
        await resetting.value
        await gateC.entered.wait()

        #expect(sut.isFullSyncing)
        gateC.release.open()
        _ = await next.result()
        #expect(!sut.isFullSyncing)
    }

    @Test func `Syncing an inactive account leaves the active account's content alone`() async {
        let operation = sut.startFullSync(userId: "inactive-user", presentation: .sheet)

        guard case .completed = await operation.result() else {
            Issue.record("Inactive account sync should complete")
            return
        }
        #expect(deleteLocalData.deletedUserIds == ["inactive-user"])
        #expect(await shareRepository.invokedCreateVaultParameters?.userId == "inactive-user")
        #expect(!itemRepository.invokedGetAllItemsfunction)
        #expect(sut.state == .loading)
        #expect(sut.currentShares.value.isEmpty)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
    }

    @Test func `Syncing an inactive account re-indexes AutoFill`() async {
        _ = await sut.startFullSync(userId: "inactive-user", presentation: .sheet).result()

        #expect(indexAllLoginItems.callCount == 1)
    }

    @Test func `Logging out an account cancels its sync and clears its marker`() async {
        let gate = refresh.pause("user-b")
        let operation = sut.startFullSync(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        let cancelRequested = Gate()
        let cancelling = Task {
            cancelRequested.open()
            await sut.cancelFullSync(userId: "user-b")
        }
        await cancelRequested.wait()
        gate.release.open()
        await cancelling.value

        guard case .cancelled = await operation.result() else {
            Issue.record("The logged out account's sync must be cancelled")
            return
        }
        #expect(deleteLocalData.deletedUserIds.isEmpty)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
        #expect(!sut.isFullSyncing)
    }

    @Test func `Logging out an account with a queued sync does not wait for the running one`() async {
        let gate = refresh.pause("user-a")
        let running = sut.startFullSync(userId: "user-a", presentation: .sheet)
        let queued = sut.startFullSync(userId: "user-b", presentation: .sheet)
        await gate.entered.wait()

        await sut.cancelFullSync(userId: "user-b")
        #expect(running.outcome == nil)

        gate.release.open()
        guard case .cancelled = await queued.result() else {
            Issue.record("The logged out account's queued sync must be cancelled")
            return
        }
        #expect(refresh.calls == ["user-a"])
    }

    @Test func `A refresh racing a reset does not publish stale content`() async {
        let refreshing = Task { await sut.refresh(userId: activeUser.user.ID) }
        await symmetricKeyProvider.entered.wait()

        await sut.reset()
        symmetricKeyProvider.release.open()
        await refreshing.value

        #expect(sut.state == .loading)
        #expect(sut.currentShares.value.isEmpty)
    }

    @Test func `A sync that owns the event loop cancels the running iteration and keeps looping`() async {
        refresh.failingUserIds = ["user-a"]
        let fullContentSync = FullContentSync(syncEventLoop: syncEventLoop, appContentManager: sut)

        let operation = fullContentSync.start(userId: "user-a", presentation: .sheet, shouldStopEventLoop: true)

        #expect(sut.isFullSyncing)
        #expect(syncEventLoop.invokedStopCount == 1)
        #expect(syncEventLoop.invokedStartCount == 1)
        _ = await operation.result()
    }

    @Test func `A sync that does not own the event loop leaves it alone`() async {
        refresh.failingUserIds = ["user-a"]
        let fullContentSync = FullContentSync(syncEventLoop: syncEventLoop, appContentManager: sut)

        let operation = fullContentSync.start(userId: "user-a", presentation: .sheet, shouldStopEventLoop: false)
        _ = await operation.result()

        #expect(syncEventLoop.invokedStopCount == 0)
        #expect(syncEventLoop.invokedStartCount == 0)
    }

    @Test func `A sync without progress fails so the user can retry`() async {
        let gate = refresh.pause("user-a")

        let stalled = sut.startFullSync(userId: "user-a", presentation: .sheet)
        guard case let .failed(error) = await stalled.result() else {
            Issue.record("A stalled sync must fail")
            return
        }
        #expect((error as? URLError)?.code == .timedOut)

        let retried = sut.startFullSync(userId: "user-a", presentation: .sheet)
        gate.release.open()
        _ = await retried.result()

        #expect(retried !== stalled)
        #expect(refresh.calls == ["user-a", "user-a"])
        #expect(deleteLocalData.deletedUserIds == ["user-a"])
    }

    @Test func `Another account completing its sync keeps an interrupted account marked`() async {
        refresh.failingUserIds = ["user-a"]

        _ = await sut.startFullSync(userId: "user-a", presentation: .sheet).result()
        _ = await sut.startFullSync(userId: "inactive-user", presentation: .sheet).result()

        #expect(sut.incompleteFullSyncUserIds == ["user-a"])
    }

    @Test func `An interrupted account marked by an older version is resumed and cleared`() async {
        kSharedUserDefaults.set("inactive-user", forKey: Constants.incompleteFullSyncUserId)
        #expect(sut.incompleteFullSyncUserIds == ["inactive-user"])

        _ = await sut.startFullSync(userId: "inactive-user", presentation: .sheet).result()

        #expect(sut.incompleteFullSyncUserIds.isEmpty)
        #expect(kSharedUserDefaults.string(forKey: Constants.incompleteFullSyncUserId) == nil)
    }

    @Test func `Slow steps are not a stall as long as the sync moves on`() async {
        refresh.delay = .milliseconds(300)
        deleteLocalData.delay = .milliseconds(300)
        await aliasSynchronizer.slowDown(pages: 5, each: .milliseconds(300))

        let operation = sut.startFullSync(userId: "user-a", presentation: .sheet)

        guard case .completed = await operation.result() else {
            Issue.record("Each step is under the stall timeout, the sync must complete")
            return
        }
    }

    @Test func `Switching account during the final load still completes the sync`() async {
        let operation = sut.startFullSync(userId: activeUser.user.ID, presentation: .sheet)
        await symmetricKeyProvider.entered.wait()

        currentActiveUser.send(UserData.random())
        symmetricKeyProvider.release.open()

        guard case .completed = await operation.result() else {
            Issue.record("The switched away account is fully synced and must not be resynced later")
            return
        }
        #expect(sut.state == .loading)
        #expect(sut.incompleteFullSyncUserIds.isEmpty)
    }
}

private enum FullSyncTestError: Error {
    case offline
}

@MainActor
private final class RefreshUserDataFake: RefreshUserDataUseCase {
    private(set) var calls: [String] = []
    var failingUserIds: Set<String> = []
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
            throw FullSyncTestError.offline
        }
    }
}

@MainActor
private final class Gate {
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
    var delay: Duration?

    nonisolated func execute(userId: String) async throws {
        try await record(userId)
    }

    private func record(_ userId: String) async throws {
        deletedUserIds.append(userId)
        if let delay {
            try await Task.sleep(for: delay)
        }
    }
}

@MainActor
private final class IndexAllLoginItemsSpy: IndexAllLoginItemsUseCase {
    private(set) var callCount = 0

    nonisolated func execute() async throws {
        await record()
    }

    private func record() {
        callCount += 1
    }
}

private actor AliasSynchronizerFake: SimpleLoginNoteSynchronizerProtocol {
    private var pageDelays: [Duration] = []

    func slowDown(pages: Int, each delay: Duration) {
        pageDelays = Array(repeating: delay, count: pages)
    }

    func syncAllAliases(userId: String,
                        onPageSynced: nonisolated(nonsending) @escaping @Sendable () async -> Void)
        async throws -> Bool {
        for delay in pageDelays {
            try await Task.sleep(for: delay)
            await onPageSynced()
        }
        return !pageDelays.isEmpty
    }

    func syncAliases(userId: String, aliases: [any ItemIdentifiable]) async throws -> Bool {
        false
    }
}

private struct SyncWorkStub: GetAndStoreLastEventIdUseCase, IndexItemsForSpotlightUseCase, DedupShareUseCase {
    func callAsFunction(userId: String) async throws {}

    func execute(_ settings: any SpotlightSettingsProvider) async throws {}

    func execute(shares: [Share], filterHidden: Bool) -> [Share] {
        shares
    }
}

@MainActor
private final class GatedSymmetricKeyProvider: SymmetricKeyProvider {
    let entered = Gate()
    let release = Gate()

    nonisolated func getSymmetricKey() async throws -> SymmetricKey {
        await pass()
        return SymmetricKey(size: .bits256)
    }

    private func pass() async {
        entered.open()
        await release.wait()
    }
}
