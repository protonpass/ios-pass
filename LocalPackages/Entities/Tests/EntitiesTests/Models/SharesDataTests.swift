//
// SharesDataTests.swift
// Proton Pass - Created on 02/02/2026.
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

@testable import Entities
import EntitiesMocks
import Testing

// MARK: - SharesDataTests

@Suite("SharesData Tests")
struct SharesDataTests {
    // MARK: - Initialization Tests

    @Test
    func `Init with empty shares and trashedItems creates empty SharesData`() {
        let sharesData = SharesData(shares: [], trashedItems: [])

        #expect(sharesData.shares.isEmpty)
        #expect(sharesData.trashedItems.isEmpty)
        #expect(sharesData.itemsSharedByMe.isEmpty)
        #expect(sharesData.itemsSharedWithMe.isEmpty)
    }

    @Test
    func `Init builds dictionary correctly from shares array`() {
        let share1 = Share.random(shareID: "share-1")
        let share2 = Share.random(shareID: "share-2")

        let content1 = ShareContent(share: share1, elements: [])
        let content2 = ShareContent(share: share2, elements: [])

        let sharesData = SharesData(shares: [content1, content2], trashedItems: [])

        #expect(sharesData.shares.count == 2)
        #expect(sharesData.shares["share-1"]?.id == "share-1")
        #expect(sharesData.shares["share-2"]?.id == "share-2")
    }

    @Test
    func `Init stores trashedItems correctly`() {
        let trashedItem1 = ItemUiModel.mock(itemId: "trashed-1", shareId: "share-1", state: .trashed)
        let trashedItem2 = ItemUiModel.mock(itemId: "trashed-2", shareId: "share-1", state: .trashed)

        let sharesData = SharesData(shares: [], trashedItems: [trashedItem1, trashedItem2])

        #expect(sharesData.trashedItems.count == 2)
    }

    // MARK: - itemsSharedByMe Tests

    @Test
    func `itemsSharedByMe includes shared items from manager role shares`() {
        // Create a manager share (shareRoleID = "1")
        let managerShare = Share.random(shareID: "manager-share", shareRoleID: "1")
        let sharedItem = ItemUiModel.mock(itemId: "shared-item", shareId: "manager-share", shared: true)

        let content = ShareContent(share: managerShare, elements: [.item(sharedItem)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedByMe.count == 1)
        #expect(sharesData.itemsSharedByMe.first?.itemId == "shared-item")
    }

    @Test
    func `itemsSharedByMe excludes non-shared items from manager shares`() {
        let managerShare = Share.random(shareID: "manager-share", shareRoleID: "1")
        let nonSharedItem = ItemUiModel.mock(itemId: "non-shared", shareId: "manager-share", shared: false)

        let content = ShareContent(share: managerShare, elements: [.item(nonSharedItem)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedByMe.isEmpty)
    }

    @Test
    func `itemsSharedByMe excludes items from non-manager shares`() {
        // Create a read-only share (shareRoleID = "3")
        let readShare = Share.random(shareID: "read-share", shareRoleID: "3")
        let sharedItem = ItemUiModel.mock(itemId: "shared-item", shareId: "read-share", shared: true)

        let content = ShareContent(share: readShare, elements: [.item(sharedItem)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedByMe.isEmpty)
    }

    @Test
    func `itemsSharedByMe includes shared trashed items from manager shares`() {
        let managerShare = Share.random(shareID: "manager-share", shareRoleID: "1")
        let content = ShareContent(share: managerShare, elements: [])

        let trashedSharedItem = ItemUiModel.mock(
            itemId: "trashed-shared",
            shareId: "manager-share",
            state: .trashed,
            shared: true
        )

        let sharesData = SharesData(shares: [content], trashedItems: [trashedSharedItem])

        #expect(sharesData.itemsSharedByMe.count == 1)
        #expect(sharesData.itemsSharedByMe.first?.itemId == "trashed-shared")
    }

    // MARK: - itemsSharedWithMe Tests

    @Test
    func `itemsSharedWithMe includes items from non-vault non-owner shares`() {
        // Create item share (targetType = 2) where user is not owner
        let itemShare = Share.random(shareID: "item-share", targetType: 2, owner: false)
        let item = ItemUiModel.mock(itemId: "shared-item", shareId: "item-share")

        let content = ShareContent(share: itemShare, elements: [.item(item)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedWithMe.count == 1)
        #expect(sharesData.itemsSharedWithMe.first?.itemId == "shared-item")
    }

    @Test
    func `itemsSharedWithMe excludes items from vault shares`() {
        // Create vault share (targetType = 1) where user is not owner
        let vaultShare = Share.random(shareID: "vault-share", targetType: 1, owner: false)
        let item = ItemUiModel.mock(itemId: "vault-item", shareId: "vault-share")

        let content = ShareContent(share: vaultShare, elements: [.item(item)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedWithMe.isEmpty)
    }

    @Test
    func `itemsSharedWithMe excludes items from owner shares`() {
        let ownerShare = Share.random(shareID: "owner-share", targetType: 2, owner: true)
        let item = ItemUiModel.mock(itemId: "my-item", shareId: "owner-share")

        let content = ShareContent(share: ownerShare, elements: [.item(item)])
        let sharesData = SharesData(shares: [content], trashedItems: [])

        #expect(sharesData.itemsSharedWithMe.isEmpty)
    }

    @Test
    func `itemsSharedWithMe includes trashed items from qualifying shares`() {
        let itemShare = Share.random(shareID: "item-share", targetType: 2, owner: false)
        let content = ShareContent(share: itemShare, elements: [])

        let trashedItem = ItemUiModel.mock(
            itemId: "trashed-item",
            shareId: "item-share",
            state: .trashed,
            shared: true
        )

        let sharesData = SharesData(shares: [content], trashedItems: [trashedItem])

        #expect(sharesData.itemsSharedWithMe.count == 1)
        #expect(sharesData.itemsSharedWithMe.first?.itemId == "trashed-item")
    }

    // MARK: - filteredOrderedVaults Tests

    @Test
    func `filteredOrderedVaults returns only shares with vaultName`() {
        let vaultShare = Share.random(shareID: "vault-share", targetType: 1)
            .copy(with: VaultContent(name: "My Vault", description: "", color: .color1, icon: .icon1))
        let itemShare = Share.random(shareID: "item-share", targetType: 2)

        let vaultContent = ShareContent(share: vaultShare, elements: [])
        let itemContent = ShareContent(share: itemShare, elements: [])

        let sharesData = SharesData(shares: [vaultContent, itemContent], trashedItems: [])

        let vaults = sharesData.filteredOrderedVaults
        #expect(vaults.count == 1)
        #expect(vaults.first?.id == "vault-share")
    }

    @Test
    func `filteredOrderedVaults sorts by name alphabetically`() {
        let vaultA = Share.random(shareID: "vault-a", targetType: 1, createTime: 100)
            .copy(with: VaultContent(name: "Alpha", description: "", color: .color1, icon: .icon1))
        let vaultB = Share.random(shareID: "vault-b", targetType: 1, createTime: 50)
            .copy(with: VaultContent(name: "Beta", description: "", color: .color1, icon: .icon1))
        let vaultC = Share.random(shareID: "vault-c", targetType: 1, createTime: 200)
            .copy(with: VaultContent(name: "Charlie", description: "", color: .color1, icon: .icon1))

        let contentA = ShareContent(share: vaultA, elements: [])
        let contentB = ShareContent(share: vaultB, elements: [])
        let contentC = ShareContent(share: vaultC, elements: [])

        let sharesData = SharesData(shares: [contentC, contentA, contentB], trashedItems: [])

        let vaults = sharesData.filteredOrderedVaults
        #expect(vaults.count == 3)
        #expect(vaults[0].share.vaultName == "Alpha")
        #expect(vaults[1].share.vaultName == "Beta")
        #expect(vaults[2].share.vaultName == "Charlie")
    }

    @Test
    func `filteredOrderedVaults sorts by createTime when names are equal`() {
        let vault1 = Share.random(shareID: "vault-1", targetType: 1, createTime: 100)
            .copy(with: VaultContent(name: "Same Name", description: "", color: .color1, icon: .icon1))
        let vault2 = Share.random(shareID: "vault-2", targetType: 1, createTime: 50)
            .copy(with: VaultContent(name: "Same Name", description: "", color: .color1, icon: .icon1))
        let vault3 = Share.random(shareID: "vault-3", targetType: 1, createTime: 200)
            .copy(with: VaultContent(name: "Same Name", description: "", color: .color1, icon: .icon1))

        let content1 = ShareContent(share: vault1, elements: [])
        let content2 = ShareContent(share: vault2, elements: [])
        let content3 = ShareContent(share: vault3, elements: [])

        let sharesData = SharesData(shares: [content3, content1, content2], trashedItems: [])

        let vaults = sharesData.filteredOrderedVaults
        #expect(vaults.count == 3)
        #expect(vaults[0].id == "vault-2") // createTime 50
        #expect(vaults[1].id == "vault-1") // createTime 100
        #expect(vaults[2].id == "vault-3") // createTime 200
    }

    // MARK: - isEmpty Tests

    @Test
    func `isEmpty returns true when all collections are empty`() {
        let sharesData = SharesData(shares: [], trashedItems: [])
        #expect(sharesData.isEmpty)
    }

    @Test
    func `isEmpty returns false when shares is not empty`() {
        let share = Share.random(shareID: "share-1")
        let content = ShareContent(share: share, elements: [])

        let sharesData = SharesData(shares: [content], trashedItems: [])
        #expect(!sharesData.isEmpty)
    }

    @Test
    func `isEmpty returns false when trashedItems is not empty`() {
        let trashedItem = ItemUiModel.mock(itemId: "trashed", shareId: "share-1", state: .trashed)
        let sharesData = SharesData(shares: [], trashedItems: [trashedItem])
        #expect(!sharesData.isEmpty)
    }

    @Test
    func `isEmpty returns false when itemsSharedByMe is not empty`() {
        let managerShare = Share.random(shareID: "manager-share", shareRoleID: "1")
        let sharedItem = ItemUiModel.mock(itemId: "shared", shareId: "manager-share", shared: true)
        let content = ShareContent(share: managerShare, elements: [.item(sharedItem)])

        let sharesData = SharesData(shares: [content], trashedItems: [])
        #expect(!sharesData.isEmpty)
    }

    @Test
    func `isEmpty returns false when itemsSharedWithMe is not empty`() {
        let itemShare = Share.random(shareID: "item-share", targetType: 2, owner: false)
        let item = ItemUiModel.mock(itemId: "item", shareId: "item-share")
        let content = ShareContent(share: itemShare, elements: [.item(item)])

        let sharesData = SharesData(shares: [content], trashedItems: [])
        #expect(!sharesData.isEmpty)
    }

    // MARK: - hiddenSharesIds Tests

    @Test
    func `hiddenSharesIds returns IDs of hidden shares`() {
        // flags = 1 means hidden (ShareFlags.hidden = 1 << 0)
        let hiddenShare = Share.random(shareID: "hidden-share", flags: 1)
        let visibleShare = Share.random(shareID: "visible-share", flags: 0)

        let hiddenContent = ShareContent(share: hiddenShare, elements: [])
        let visibleContent = ShareContent(share: visibleShare, elements: [])

        let sharesData = SharesData(shares: [hiddenContent, visibleContent], trashedItems: [])

        #expect(sharesData.hiddenSharesIds.count == 1)
        #expect(sharesData.hiddenSharesIds.contains("hidden-share"))
    }

    @Test
    func `hiddenSharesIds returns empty when no hidden shares`() {
        let visibleShare1 = Share.random(shareID: "visible-1", flags: 0)
        let visibleShare2 = Share.random(shareID: "visible-2", flags: 0)

        let content1 = ShareContent(share: visibleShare1, elements: [])
        let content2 = ShareContent(share: visibleShare2, elements: [])

        let sharesData = SharesData(shares: [content1, content2], trashedItems: [])

        #expect(sharesData.hiddenSharesIds.isEmpty)
    }

    // MARK: - visibleShareContents Tests

    @Test
    func `visibleShareContents returns only non-hidden shares`() {
        let hiddenShare = Share.random(shareID: "hidden-share", flags: 1)
        let visibleShare = Share.random(shareID: "visible-share", flags: 0)

        let hiddenContent = ShareContent(share: hiddenShare, elements: [])
        let visibleContent = ShareContent(share: visibleShare, elements: [])

        let sharesData = SharesData(shares: [hiddenContent, visibleContent], trashedItems: [])

        #expect(sharesData.visibleShareContents.count == 1)
        #expect(sharesData.visibleShareContents.first?.id == "visible-share")
    }

    @Test
    func `visibleShareContents returns all shares when none are hidden`() {
        let share1 = Share.random(shareID: "share-1", flags: 0)
        let share2 = Share.random(shareID: "share-2", flags: 0)

        let content1 = ShareContent(share: share1, elements: [])
        let content2 = ShareContent(share: share2, elements: [])

        let sharesData = SharesData(shares: [content1, content2], trashedItems: [])

        #expect(sharesData.visibleShareContents.count == 2)
    }

    // MARK: - Complex Scenario Tests

    @Test
    func `Complex scenario with mixed shares and items`() {
        // Manager share with shared items
        let managerShare = Share.random(shareID: "manager-share", targetType: 2, shareRoleID: "1", owner: true)
        let sharedByMeItem = ItemUiModel.mock(itemId: "shared-by-me", shareId: "manager-share", shared: true)
        let notSharedItem = ItemUiModel.mock(itemId: "not-shared", shareId: "manager-share", shared: false)
        let managerContent = ShareContent(
            share: managerShare,
            elements: [.item(sharedByMeItem), .item(notSharedItem)]
        )

        // Item share where I'm not owner
        let sharedWithMeShare = Share.random(shareID: "shared-with-me-share", targetType: 2, shareRoleID: "3", owner: false)
        let sharedWithMeItem = ItemUiModel.mock(itemId: "shared-with-me", shareId: "shared-with-me-share")
        let sharedWithMeContent = ShareContent(share: sharedWithMeShare, elements: [.item(sharedWithMeItem)])

        // Vault share (visible)
        let vaultShare = Share.random(shareID: "vault-share", targetType: 1, flags: 0)
            .copy(with: VaultContent(name: "My Vault", description: "", color: .color1, icon: .icon1))
        let vaultContent = ShareContent(share: vaultShare, elements: [])

        // Hidden share
        let hiddenShare = Share.random(shareID: "hidden-share", flags: 1)
        let hiddenContent = ShareContent(share: hiddenShare, elements: [])

        // Trashed items
        let trashedSharedByMe = ItemUiModel.mock(
            itemId: "trashed-shared-by-me",
            shareId: "manager-share",
            state: .trashed,
            shared: true
        )
        let trashedSharedWithMe = ItemUiModel.mock(
            itemId: "trashed-shared-with-me",
            shareId: "shared-with-me-share",
            state: .trashed,
            shared: true
        )
        let trashedNotShared = ItemUiModel.mock(
            itemId: "trashed-not-shared",
            shareId: "manager-share",
            state: .trashed,
            shared: false
        )

        let sharesData = SharesData(
            shares: [managerContent, sharedWithMeContent, vaultContent, hiddenContent],
            trashedItems: [trashedSharedByMe, trashedSharedWithMe, trashedNotShared]
        )

        // Verify shares dictionary
        #expect(sharesData.shares.count == 4)

        // Verify trashedItems
        #expect(sharesData.trashedItems.count == 3)

        // Verify itemsSharedByMe: sharedByMeItem + trashedSharedByMe
        #expect(sharesData.itemsSharedByMe.count == 2)
        let sharedByMeIds = sharesData.itemsSharedByMe.map(\.itemId)
        #expect(sharedByMeIds.contains("shared-by-me"))
        #expect(sharedByMeIds.contains("trashed-shared-by-me"))

        // Verify itemsSharedWithMe: sharedWithMeItem + trashedSharedWithMe
        #expect(sharesData.itemsSharedWithMe.count == 2)
        let sharedWithMeIds = sharesData.itemsSharedWithMe.map(\.itemId)
        #expect(sharedWithMeIds.contains("shared-with-me"))
        #expect(sharedWithMeIds.contains("trashed-shared-with-me"))

        // Verify isEmpty
        #expect(!sharesData.isEmpty)

        // Verify filteredOrderedVaults
        #expect(sharesData.filteredOrderedVaults.count == 1)
        #expect(sharesData.filteredOrderedVaults.first?.id == "vault-share")

        // Verify hiddenSharesIds
        #expect(sharesData.hiddenSharesIds.count == 1)
        #expect(sharesData.hiddenSharesIds.contains("hidden-share"))

        // Verify visibleShareContents
        #expect(sharesData.visibleShareContents.count == 3)
    }

    // MARK: - items(for:) Tests

    /// Vault `vault-1` with a root item, a root folder holding one item, and a nested
    /// sub folder holding one item.
    private func nestedVault() -> ShareContent {
        let share = Share.random(shareID: "vault-1", targetType: 1)
        let parentFolder = FolderUiModel.mock(folderId: "folder-parent", shareId: "vault-1")
        let childFolder = FolderUiModel.mock(folderId: "folder-child",
                                             shareId: "vault-1",
                                             parentFolderId: "folder-parent")
        return ShareContent(share: share,
                            elements: [
                                .item(ItemUiModel.mock(itemId: "root-item", shareId: "vault-1")),
                                .folder(parentFolder),
                                .item(ItemUiModel.mock(itemId: "parent-item",
                                                       shareId: "vault-1",
                                                       folderId: "folder-parent")),
                                .folder(childFolder),
                                .item(ItemUiModel.mock(itemId: "child-item",
                                                       shareId: "vault-1",
                                                       folderId: "folder-child"))
                            ])
    }

    @Test
    func `items(for:) on a folder returns its direct children only`() throws {
        let content = nestedVault()
        let sharesData = SharesData(shares: [content], trashedItems: [])
        let folder = try #require(content.folder(for: "folder-parent"))

        let items = sharesData.items(for: .precise(.init(share: content.share, folder: folder)))

        #expect(items.map(\.itemId) == ["parent-item"])
    }

    @Test
    func `items(for:) on a vault returns root items only`() {
        let content = nestedVault()
        let sharesData = SharesData(shares: [content], trashedItems: [])

        let items = sharesData.items(for: .precise(.init(share: content.share, folder: nil)))

        #expect(items.map(\.itemId) == ["root-item"])
    }

    @Test
    func `items(for:) on an unknown share returns nothing`() {
        let sharesData = SharesData(shares: [], trashedItems: [])
        let share = Share.random(shareID: "missing", targetType: 1)

        #expect(sharesData.items(for: .precise(.init(share: share, folder: nil))).isEmpty)
    }

    @Test
    func `items(for: .all) excludes items of hidden shares`() {
        let visible = ShareContent(share: Share.random(shareID: "visible", targetType: 1),
                                   elements: [.item(ItemUiModel.mock(itemId: "visible-item",
                                                                     shareId: "visible"))])
        let hidden = ShareContent(share: Share.random(shareID: "hidden", targetType: 1, flags: 1),
                                  elements: [.item(ItemUiModel.mock(itemId: "hidden-item",
                                                                    shareId: "hidden"))])
        let sharesData = SharesData(shares: [visible, hidden], trashedItems: [])

        #expect(sharesData.items(for: .all).map(\.itemId) == ["visible-item"])
    }

    @Test
    func `items(for: .trash) excludes trashed items of hidden shares`() {
        let visible = ShareContent(share: Share.random(shareID: "visible", targetType: 1), elements: [])
        let hidden = ShareContent(share: Share.random(shareID: "hidden", targetType: 1, flags: 1),
                                  elements: [])
        let trashedItems = [
            ItemUiModel.mock(itemId: "visible-trashed", shareId: "visible", state: .trashed),
            ItemUiModel.mock(itemId: "hidden-trashed", shareId: "hidden", state: .trashed)
        ]
        let sharesData = SharesData(shares: [visible, hidden], trashedItems: trashedItems)

        #expect(sharesData.items(for: .trash).map(\.itemId) == ["visible-trashed"])
    }

    // MARK: - Hashable Tests

    @Test
    func `SharesData is hashable`() {
        let share = Share.random(shareID: "share-1")
        let content = ShareContent(share: share, elements: [])
        let trashedItem = ItemUiModel.mock(itemId: "trashed", shareId: "share-1", state: .trashed)

        let sharesData1 = SharesData(shares: [content], trashedItems: [trashedItem])
        let sharesData2 = SharesData(shares: [content], trashedItems: [trashedItem])

        #expect(sharesData1.hashValue == sharesData2.hashValue)
    }
}
