//
// ItemRepositoryTests.swift
// Proton Pass - Created on 01/12/2023.
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

@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import ProtonCoreFeatureFlags
import ProtonCoreLogin
import Testing

@Suite(.tags(.repository))
struct ItemRepositoryTests {
    private let symmetricKeyProvider: SymmetricKeyProviderMock
    private let userManager: UserManagerProtocolMock
    private let localDatasource: LocalItemDatasourceProtocolMock
    private let remoteDatasource: RemoteItemDatasourceProtocolMock
    private let localShareDatasource: LocalShareDatasourceProtocolMock
    private let shareEventIDRepository: ShareEventIDRepositoryProtocolMock
    private let passKeyManager: PassKeyManagerProtocolMock
    private let featureFlagsRepository: FeatureFlagsRepositoryMock
    private let logManager: LogManagerProtocolMock

    init() {
        symmetricKeyProvider = SymmetricKeyProviderMock()
        userManager = UserManagerProtocolMock()
        localDatasource = LocalItemDatasourceProtocolMock()
        localDatasource.stubbedGetAllPinnedItemsResult = []
        remoteDatasource = RemoteItemDatasourceProtocolMock()
        localShareDatasource = LocalShareDatasourceProtocolMock()
        shareEventIDRepository = ShareEventIDRepositoryProtocolMock()
        passKeyManager = PassKeyManagerProtocolMock()
        featureFlagsRepository = FeatureFlagsRepositoryMock()
        logManager = LogManagerProtocolMock()
    }
}

// MARK: - Pinned tests

extension ItemRepositoryTests {
    @Test(.timeLimit(.minutes(1)))
    func `get all pinned items`() async throws {
        let user = UserData.preview
        let shareId = UUID().uuidString
        localShareDatasource.stubbedGetAllSharesUserIdAsyncResult2 =
            [SymmetricallyEncryptedShare(encryptedContent: nil,
                                         share: .random(shareId: shareId))]
        localDatasource.stubbedGetAllPinnedItemsResult =
            [SymmetricallyEncryptedItem].random(count: 10,
                                                randomElement: .random(shareId: shareId,
                                                                       userId: user.user.ID,
                                                                       item: .random(pinned: true)))
        userManager.stubbedGetActiveUserDataResult = user

        let sut = ItemRepository(symmetricKeyProvider: symmetricKeyProvider,
                                 userManager: userManager,
                                 localDatasource: localDatasource,
                                 remoteDatasource: remoteDatasource,
                                 localShareDatasource: localShareDatasource,
                                 shareEventIDRepository: shareEventIDRepository,
                                 passKeyManager: passKeyManager,
                                 featureFlagsRepository: featureFlagsRepository,
                                 logManager: logManager)

        let pinnedItems = try await sut.getAllPinnedItems()
        #expect(pinnedItems.count == 10)

        var loaded: [SymmetricallyEncryptedItem]?
        for await value in sut.currentlyPinnedItems.values {
            if let value {
                loaded = value
                break
            }
        }

        let items = try #require(loaded)
        #expect(items.count == 10)
        #expect(localDatasource.invokedGetAllPinnedItemsfunction)
  
        #expect(localDatasource.invokedGetAllPinnedItemsCount == 2)
    }
}

// MARK: - Get shared item tests

extension ItemRepositoryTests {
    @Test
    func `get shared item throws when share is not an item share`() async throws {
        let share = Share.random(shareId: .random(), targetType: .vault)
        let sut = makeSut()

        await #expect(throws: PassError.itemShareExpected(share)) {
            try await sut.getSharedItem(userId: .random(), share: share)
        }
        #expect(!remoteDatasource.invokedGetItemRevisionsfunction)
        #expect(!localDatasource.invokedUpsertItemsItemsAsync12)
    }

    @Test
    func `get shared item throws when there is no remote revision`() async throws {
        let share = Share.random(shareId: .random(), targetType: .item)
        remoteDatasource.stubbedGetItemRevisionsResult = .init(lastToken: nil, data: [], total: 0)
        let sut = makeSut()

        await #expect(throws: PassError.sharedItemNotFound(share)) {
            try await sut.getSharedItem(userId: .random(), share: share)
        }
        #expect(!localDatasource.invokedUpsertItemsItemsAsync12)
    }

    @Test
    func `get shared item caches and returns the latest revision`() async throws {
        let userId = String.random()
        let share = Share.random(shareId: .random(), targetType: .item)
        let containerKey = try DecryptedShareKey(shareId: share.shareID, keyRotation: 1, keyData: .random())
        let name = String.random()
        let latestRevision = try makeEncryptedItem(itemId: share.targetID, name: name, containerKey: containerKey)
        let olderRevision = try makeEncryptedItem(itemId: share.targetID,
                                                  name: .random(),
                                                  containerKey: containerKey)
        stubDecryptionDependencies(userId: userId, share: share, containerKey: containerKey)
        remoteDatasource.stubbedGetItemRevisionsResult = .init(lastToken: nil,
                                                               data: [latestRevision, olderRevision],
                                                               total: 2)
        let localDatasource = localDatasource
        localDatasource.closureUpsertItemsItemsAsync12 = {
            localDatasource.stubbedGetItemResult =
                localDatasource.invokedUpsertItemsItemsAsyncParameters12?.items.first
        }
        let sut = makeSut()

        let content = try #require(await sut.getSharedItem(userId: userId, share: share))

        #expect(content.name == name)
        #expect(content.itemId == share.targetID)
        #expect(content.shareId == share.shareID)
        #expect(content.userId == userId)

        let revisionsParams = try #require(remoteDatasource.invokedGetItemRevisionsParameters)
        #expect(revisionsParams.userId == userId)
        #expect(revisionsParams.shareId == share.shareID)
        #expect(revisionsParams.itemId == share.targetID)
        #expect(revisionsParams.lastToken == nil)

        let upserted = try #require(localDatasource.invokedUpsertItemsItemsAsyncParameters12?.items)
        #expect(upserted.count == 1)
        #expect(upserted.first?.item == latestRevision)
        #expect(upserted.first?.userId == userId)
        #expect(upserted.first?.shareId == share.shareID)
        #expect(localDatasource.invokedGetItemParameters?.shareId == share.shareID)
        #expect(localDatasource.invokedGetItemParameters?.itemId == share.targetID)
    }

    @Test
    func `get shared item throws when cached item cannot be read back`() async throws {
        let userId = String.random()
        let share = Share.random(shareId: .random(), targetType: .item)
        let containerKey = try DecryptedShareKey(shareId: share.shareID, keyRotation: 1, keyData: .random())
        let revision = try makeEncryptedItem(itemId: share.targetID, name: .random(), containerKey: containerKey)
        stubDecryptionDependencies(userId: userId, share: share, containerKey: containerKey)
        remoteDatasource.stubbedGetItemRevisionsResult = .init(lastToken: nil, data: [revision], total: 1)
        localDatasource.stubbedGetItemResult = nil
        let sut = makeSut()

        await #expect {
            try await sut.getSharedItem(userId: userId, share: share)
        } throws: { error in
            guard case let .itemNotFound(item) = error as? PassError else { return false }
            return item.itemId == share.targetID && item.shareId == share.shareID
        }
        #expect(localDatasource.invokedUpsertItemsItemsAsync12)
    }
}

private extension ItemRepositoryTests {
    func makeSut() -> ItemRepository {
        ItemRepository(symmetricKeyProvider: symmetricKeyProvider,
                       userManager: userManager,
                       localDatasource: localDatasource,
                       remoteDatasource: remoteDatasource,
                       localShareDatasource: localShareDatasource,
                       shareEventIDRepository: shareEventIDRepository,
                       passKeyManager: passKeyManager,
                       logManager: logManager)
    }

    func stubDecryptionDependencies(userId: String,
                                    share: Share,
                                    containerKey: any CryptographicKeyProtocol) {
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = SymmetricKey(size: .bits256)
        localShareDatasource.stubbedGetShareResult = .init(encryptedContent: nil, share: share)
        passKeyManager.stubbedGetContainerKeyResult = containerKey
    }

    func makeEncryptedItem(itemId: String,
                           name: String,
                           containerKey: any CryptographicKeyProtocol) throws -> Item {
        let protobuf = ItemContentProtobufFactory.createItemContentProtobuf(name: name,
                                                                            note: .random(),
                                                                            itemUuid: .random(),
                                                                            data: .note,
                                                                            customFields: [])
        let itemKey = try Data.random()
        let content = try AES.GCM.seal(protobuf.data(), key: itemKey, associatedData: .itemContent)
        let encryptedItemKey = try AES.GCM.seal(itemKey, key: containerKey.keyData, associatedData: .itemKey)
        return Item(itemID: itemId,
                    revision: .random(in: 1...100),
                    contentFormatVersion: 1,
                    keyRotation: containerKey.keyRotation,
                    content: content.base64EncodedString(),
                    itemKey: encryptedItemKey.base64EncodedString(),
                    state: ItemState.active.rawValue,
                    pinned: false,
                    pinTime: nil,
                    aliasEmail: nil,
                    createTime: .random(in: 0...1_000_000),
                    modifyTime: .random(in: 0...1_000_000),
                    lastUseTime: nil,
                    revisionTime: .random(in: 0...1_000_000),
                    flags: 0,
                    shareCount: 1,
                    folderID: nil)
    }
}
