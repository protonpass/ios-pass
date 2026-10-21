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
    private let fullSyncManager = FullSyncManagerProtocolMock()
    private let indexAllLoginItems = IndexAllLoginItemsSpy()
    private let itemRepository = ItemRepositoryProtocolMock()
    private let shareRepository = ShareRepositoryProtocolMock()
    private let folderRepository = FolderRepositoryProtocolMock()
    private let symmetricKeyProvider = GatedSymmetricKeyProvider()
    private let loginMethod = LoginMethodFlow()
    private let activeUser = UserData.random()
    private let currentActiveUser: CurrentValueSubject<UserData?, Never>
    private let preferences: PreferencesManager
    private let sut: AppContentManager

    init() {
        currentActiveUser = .init(activeUser)
        shareRepository.stubbedGetDecryptedSharesResult = []
        itemRepository.stubbedGetAllItemsResult = []
        folderRepository.stubbedGetAllLocalFoldersResult = []
        let userManager = UserManagerProtocolMock()
        userManager.stubbedCurrentActiveUser = currentActiveUser
        userManager.stubbedGetActiveUserDataResult = activeUser
        let logManager = LogManagerProtocolMock()
        preferences = PreferencesManager(userManager: userManager,
                                         appPreferencesDatasource: LocalAppPreferencesDatasourceProtocolMock(),
                                         sharedPreferencesDatasource: LocalSharedPreferencesDatasourceProtocolMock(),
                                         userPreferencesDatasource: LocalUserPreferencesDatasourceProtocolMock(),
                                         logManager: logManager)
        sut = AppContentManager(itemRepository: itemRepository,
                                shareRepository: shareRepository,
                                inviteRepository: FullInviteRepositoryProtocolMock(),
                                folderRepository: folderRepository,
                                userManager: userManager,
                                fullSyncManager: fullSyncManager,
                                preferencesManager: preferences,
                                symmetricKeyProvider: symmetricKeyProvider,
                                indexAllLoginItems: indexAllLoginItems,
                                indexItemsForSpotlight: SyncWorkStub(),
                                dedupShare: SyncWorkStub(),
                                logger: Logger(manager: logManager),
                                loginMethod: loginMethod)
    }

    @Test func `A completed sync shows the active account's vaults`() async throws {
        let vault = Share.random(targetType: 1)
        shareRepository.stubbedGetDecryptedSharesResult = [vault]
        symmetricKeyProvider.release.open()

        try await sut.fullSyncDidStoreContent(userId: activeUser.user.ID)

        #expect(sut.currentShares.value.map(\.shareID) == [vault.shareID])
        #expect(sut.state.loadedContent?.shares.count == 1)
    }

    @Test func `Logging in runs the full sync with the inline progress`() async {
        stubSync(outcome: .completed(hasUndecryptableShares: false))
        await loginMethod.setLogInFlow(newState: true)

        await sut.refresh(userId: activeUser.user.ID)

        #expect(fullSyncManager.invokedStartParameters?.userId == activeUser.user.ID)
        #expect(fullSyncManager.invokedStartParameters?.presentation == .inline)
        #expect(await loginMethod.isManualLogIn() == false)
    }

    @Test(arguments: [true, false])
    func `Only a login sync failing on an inactive key shows the local content`(inactiveKey: Bool) async {
        let error: any Error = inactiveKey
            ? PassError.crypto(.inactiveUserKey(userKeyId: "key"))
            : URLError(.timedOut)
        stubSync(outcome: .failed(error))
        symmetricKeyProvider.release.open()
        await loginMethod.setLogInFlow(newState: true)

        await sut.refresh(userId: activeUser.user.ID)

        #expect((sut.state.loadedContent != nil) == inactiveKey,
                "Other failures keep the retry screen over the loading state")
    }

    @Test(arguments: [true, false])
    func `Only the active account's sync marks its folder repair done`(syncsActiveAccount: Bool) async throws {
        try await preferences.setUp()
        symmetricKeyProvider.release.open()

        let userId = syncsActiveAccount ? activeUser.user.ID : "inactive-user"
        try await sut.fullSyncDidStoreContent(userId: userId)

        #expect(preferences.userPreferences.value?.folderForceSync.done == syncsActiveAccount)
    }

    @Test func `Syncing an inactive account leaves the active account's content alone`() async throws {
        try await sut.fullSyncDidStoreContent(userId: "inactive-user")

        #expect(!itemRepository.invokedGetAllItemsfunction)
        #expect(sut.state == .loading)
        #expect(sut.currentShares.value.isEmpty)
    }

    @Test func `Syncing an inactive account re-indexes AutoFill`() async throws {
        try await sut.fullSyncDidStoreContent(userId: "inactive-user")

        #expect(indexAllLoginItems.callCount == 1)
    }

    @Test func `Reloading an account that is no longer active leaves the content alone`() async throws {
        symmetricKeyProvider.release.open()
        try await sut.localFullSync(userId: activeUser.user.ID)

        try await sut.localFullSync(userId: "inactive-user")

        #expect(sut.state.loadedContent != nil)
    }

    @Test func `Switching account during the final load still completes the sync`() async throws {
        try await preferences.setUp()
        let loading = Task { try await sut.fullSyncDidStoreContent(userId: activeUser.user.ID) }
        await symmetricKeyProvider.entered.wait()

        currentActiveUser.send(UserData.random())
        symmetricKeyProvider.release.open()

        try await loading.value
        #expect(sut.state == .loading)
        #expect(preferences.userPreferences.value?.folderForceSync.done == false,
                "The repair belongs to the switched away account")
    }
}

private extension AppContentManagerFullSyncTests {
    func stubSync(outcome: FullSyncOperation.Outcome) {
        let operation = FullSyncOperation(userId: activeUser.user.ID, presentation: .inline)
        operation.finish(outcome)
        fullSyncManager.stubbedStartResult = operation
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

private struct SyncWorkStub: IndexItemsForSpotlightUseCase, DedupShareUseCase {
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
