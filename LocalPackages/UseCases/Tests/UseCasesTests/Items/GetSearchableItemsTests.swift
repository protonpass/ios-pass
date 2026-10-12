//
// GetSearchableItemsTests.swift
// Proton Pass - Created on 05/10/2026.
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

import Client
import ClientMocks
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Testing
import UseCases
import UseCasesMocks

/// The real `DedupShare` is backed by PassRustCore, so the share filtering is stubbed.
private struct DedupShareStub: DedupShareUseCase {
    let keptShareIds: Set<String>?

    func execute(shares: [Share], filterHidden: Bool) -> [Share] {
        guard let keptShareIds else { return shares }
        return shares.filter { keptShareIds.contains($0.shareId) }
    }
}

/// `@MainActor` because `AppContentManagerProtocolMock` is main-actor isolated.
@Suite(.tags(.useCase))
@MainActor
struct GetSearchableItemsTests {
    private let key = SymmetricKey(size: .bits256)
    private let vault = Share.random(shareID: "share-1", targetType: 1)
    private let otherVault = Share.random(shareID: "share-2", targetType: 1)
    private let itemRepository = ItemRepositoryProtocolMock()
    private let getAllPinnedItems = GetAllPinnedItemsUseCaseMock()
    private let appContentManager = AppContentManagerProtocolMock()

    @Test func `items of shares filtered out by dedup are not searchable`() async throws {
        let kept = try item(shareId: "share-1")
        let dropped = try item(shareId: "share-2")
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [kept, dropped]

        let result = try await makeSUT(keptShareIds: ["share-1"])(userId: "user-1", for: .all(.all))

        #expect(result.scoped.map(\.ids) == [kept.ids])
        #expect(result.all == nil)
    }

    @Test func `pinned mode searches the pinned items only`() async throws {
        let pinned = try item(shareId: "share-1")
        getAllPinnedItems.stubbedExecuteAsyncResult2 = [pinned]
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = try [item(shareId: "share-1")]

        let result = try await makeSUT()(userId: "user-1", for: .pinned)

        #expect(result.scoped.map(\.ids) == [pinned.ids])
        #expect(result.all == nil)
    }

    @Test func `a vault selection scopes to its items while all keeps every active item`() async throws {
        let inVaultRoot = try item(shareId: "share-1")
        let inVaultFolder = try item(shareId: "share-1", folderId: "folder-1")
        let inOtherVault = try item(shareId: "share-2")
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [inVaultRoot, inVaultFolder, inOtherVault]

        let result = try await makeSUT()(userId: "user-1",
                                         for: .all(.precise(.init(share: vault, folder: nil))))

        let all = try #require(result.all)
        #expect(Set(result.scoped.map(\.ids)) == [inVaultRoot.ids, inVaultFolder.ids])
        #expect(Set(all.map(\.ids)) == [inVaultRoot.ids, inVaultFolder.ids, inOtherVault.ids])
    }

    @Test func `a folder selection includes its sub folders but not its siblings or the vault root`() async throws {
        let parent = FolderUiModel.mock(folderId: "parent", shareId: "share-1")
        let child = FolderUiModel.mock(folderId: "child", shareId: "share-1", parentFolderId: "parent")
        let sibling = FolderUiModel.mock(folderId: "sibling", shareId: "share-1")
        appContentManager.stubbedGetShareContentResult = ShareContent(share: vault,
                                                                      elements: [
                                                                          .folder(parent),
                                                                          .folder(child),
                                                                          .folder(sibling)
                                                                      ])
        let inParent = try item(shareId: "share-1", folderId: "parent")
        let inChild = try item(shareId: "share-1", folderId: "child")
        let inSibling = try item(shareId: "share-1", folderId: "sibling")
        let atRoot = try item(shareId: "share-1")
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [inParent, inChild, inSibling, atRoot]

        let result = try await makeSUT()(userId: "user-1",
                                         for: .all(.precise(.init(share: vault, folder: parent))))

        #expect(Set(result.scoped.map(\.ids)) == [inParent.ids, inChild.ids])
    }

    @Test func `a folder selection falls back to the folder alone without share content`() async throws {
        let parent = FolderUiModel.mock(folderId: "parent", shareId: "share-1")
        let inParent = try item(shareId: "share-1", folderId: "parent")
        let inChild = try item(shareId: "share-1", folderId: "child")
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [inParent, inChild]

        let result = try await makeSUT()(userId: "user-1",
                                         for: .all(.precise(.init(share: vault, folder: parent))))

        #expect(result.scoped.map(\.ids) == [inParent.ids])
    }

    @Test func `shared by me keeps the shared items the user owns the key of`() async throws {
        let sharedByMe = try item(shareId: "share-1", itemKey: "key", shareCount: 2)
        let sharedWithMe = try item(shareId: "share-1", itemKey: nil, shareCount: 2)
        let notShared = try item(shareId: "share-1", itemKey: "key", shareCount: 0)
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [sharedByMe, sharedWithMe, notShared]

        let result = try await makeSUT()(userId: "user-1", for: .all(.sharedByMe))

        #expect(result.scoped.map(\.ids) == [sharedByMe.ids])
    }

    @Test func `shared with me keeps the shared items without an item key`() async throws {
        let sharedByMe = try item(shareId: "share-1", itemKey: "key", shareCount: 2)
        let sharedWithMe = try item(shareId: "share-1", itemKey: nil, shareCount: 2)
        itemRepository.stubbedGetItemsUserIdStateAsyncResult3 = [sharedByMe, sharedWithMe]

        let result = try await makeSUT()(userId: "user-1", for: .all(.sharedWithMe))

        #expect(result.scoped.map(\.ids) == [sharedWithMe.ids])
    }
}

private extension GetSearchableItemsTests {
    func makeSUT(keptShareIds: Set<String>? = nil) -> GetSearchableItems {
        let shareRepository = ShareRepositoryProtocolMock()
        shareRepository.stubbedGetDecryptedSharesResult = [vault, otherVault]
        let symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = key
        return GetSearchableItems(itemRepository: itemRepository,
                                  shareRepository: shareRepository,
                                  getAllPinnedItems: getAllPinnedItems,
                                  dedupShare: DedupShareStub(keptShareIds: keptShareIds),
                                  symmetricKeyProvider: symmetricKeyProvider,
                                  appContentManager: appContentManager,
                                  logManager: LogManagerProtocolMock())
    }

    func item(shareId: String,
              folderId: String? = nil,
              itemKey: String? = "key",
              shareCount: Int = 0) throws -> SymmetricallyEncryptedItem {
        let item = Item(itemID: .random(),
                        revision: 1,
                        contentFormatVersion: 1,
                        keyRotation: 1,
                        content: "",
                        itemKey: itemKey,
                        state: ItemState.active.rawValue,
                        pinned: false,
                        pinTime: nil,
                        aliasEmail: nil,
                        createTime: 0,
                        modifyTime: 0,
                        lastUseTime: nil,
                        revisionTime: 0,
                        flags: 0,
                        shareCount: shareCount,
                        folderID: folderId)
        return try makeEncryptedItem(shareId: shareId, folderId: folderId, item: item, data: .note, key: key)
    }
}
