//
// ShareContentTests.swift
// Proton Pass - Created on 05/01/2026.
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

// MARK: - ShareContentTests

struct ShareContentTests {
    let shareId = "share-1"
    let share: Share

    init() {
        share = Share.random(shareID: shareId)
    }

    // MARK: - Initialization Tests

    @Test("Init with empty elements creates empty content")
    func initWithEmptyElements() {
        let content = ShareContent(share: share, elements: [])

        #expect(content.id == shareId)
        #expect(content.itemCount == 0)
        #expect(content.aliasCount == 0)
        #expect(content.totpCount == 0)
        #expect(content.allItems.isEmpty)
        #expect(content.allFolders.isEmpty)
        #expect(content.allElements.isEmpty)
    }

    @Test("Init counts items correctly")
    func initCountsItemsCorrectly() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let item2 = ItemUiModel.mock(itemId: "item-2", shareId: shareId)
        let item3 = ItemUiModel.mock(itemId: "item-3", shareId: shareId)

        let elements: [ShareContentElement] = [.item(item1), .item(item2), .item(item3)]
        let content = ShareContent(share: share, elements: elements)

        #expect(content.itemCount == 3)
        #expect(content.aliasCount == 0)
        #expect(content.totpCount == 0)
    }

    @Test("Init counts aliases correctly")
    func initCountsAliasesCorrectly() {
        let regularItem = ItemUiModel.mock(itemId: "item-1", shareId: shareId, isAlias: false)
        let aliasItem1 = ItemUiModel.mock(itemId: "alias-1", shareId: shareId, isAlias: true)
        let aliasItem2 = ItemUiModel.mock(itemId: "alias-2", shareId: shareId, isAlias: true)

        let elements: [ShareContentElement] = [.item(regularItem), .item(aliasItem1), .item(aliasItem2)]
        let content = ShareContent(share: share, elements: elements)

        #expect(content.itemCount == 3)
        #expect(content.aliasCount == 2)
    }

    @Test("Init counts TOTP correctly")
    func initCountsTotpCorrectly() {
        let itemWithoutTotp = ItemUiModel.mock(itemId: "item-1", shareId: shareId, totpUri: nil)
        let itemWithTotp1 = ItemUiModel.mock(itemId: "item-2", shareId: shareId, totpUri: "otpauth://totp/test1")
        let itemWithTotp2 = ItemUiModel.mock(itemId: "item-3", shareId: shareId, totpUri: "otpauth://totp/test2")
        let itemWithEmptyTotp = ItemUiModel.mock(itemId: "item-4", shareId: shareId, totpUri: "")

        let elements: [ShareContentElement] = [
            .item(itemWithoutTotp),
            .item(itemWithTotp1),
            .item(itemWithTotp2),
            .item(itemWithEmptyTotp)
        ]
        let content = ShareContent(share: share, elements: elements)

        #expect(content.itemCount == 4)
        #expect(content.totpCount == 2)
    }

    // MARK: - allElements Tests

    @Test("allElements returns all items and folders")
    func allElementsReturnsAllItemsAndFolders() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let item2 = ItemUiModel.mock(itemId: "item-2", shareId: shareId, folderId: "folder-1")
        let folder1 = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)

        let elements: [ShareContentElement] = [.item(item1), .item(item2), .folder(folder1)]
        let content = ShareContent(share: share, elements: elements)

        let allElements = content.allElements
        #expect(allElements.count == 3)

        let itemIds = allElements.compactMap { $0.itemValue?.itemId }
        let folderIds = allElements.compactMap { $0.folderValue?.folderId }

        #expect(itemIds.contains("item-1"))
        #expect(itemIds.contains("item-2"))
        #expect(folderIds.contains("folder-1"))
    }

    // MARK: - allItems Tests

    @Test("allItems returns only items")
    func allItemsReturnsOnlyItems() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let item2 = ItemUiModel.mock(itemId: "item-2", shareId: shareId, folderId: "folder-1")
        let folder1 = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)

        let elements: [ShareContentElement] = [.item(item1), .item(item2), .folder(folder1)]
        let content = ShareContent(share: share, elements: elements)

        let allItems = content.allItems
        #expect(allItems.count == 2)
        #expect(allItems.contains(where: { $0.itemId == "item-1" }))
        #expect(allItems.contains(where: { $0.itemId == "item-2" }))
    }

    // MARK: - allFolders Tests

    @Test("allFolders returns only folders")
    func allFoldersReturnsOnlyFolders() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let folder1 = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let folder2 = FolderUiModel.mock(folderId: "folder-2", shareId: shareId, parentFolderId: "folder-1")

        let elements: [ShareContentElement] = [.item(item1), .folder(folder1), .folder(folder2)]
        let content = ShareContent(share: share, elements: elements)

        let allFolders = content.allFolders
        #expect(allFolders.count == 2)
        #expect(allFolders.contains(where: { $0.folderId == "folder-1" }))
        #expect(allFolders.contains(where: { $0.folderId == "folder-2" }))
    }

    // MARK: - element(in:for:) Tests

    @Test("element(in:for:) returns item when found")
    func elementInContainerReturnsItemWhenFound() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.element(in: shareId, for: item.id)
        #expect(result != nil)
        #expect(result?.id == item.id)
        #expect(result?.isFolder == false)
    }

    @Test("element(in:for:) returns folder when found")
    func elementInContainerReturnsFolderWhenFound() {
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.element(in: shareId, for: "folder-1")
        #expect(result != nil)
        #expect(result?.id == "folder-1")
        #expect(result?.isFolder == true)
    }

    @Test("element(in:for:) returns nil when not found")
    func elementInContainerReturnsNilWhenNotFound() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.element(in: shareId, for: "nonexistent")
        #expect(result == nil)
    }

    @Test("element(in:for:) returns nil for wrong container")
    func elementInContainerReturnsNilForWrongContainer() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId, folderId: "folder-1")
        let elements: [ShareContentElement] = [.item(item)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.element(in: shareId, for: item.id)
        #expect(result == nil)
    }

    // MARK: - elements(for:) Tests

    @Test("elements(for:) returns items and folders in container")
    func elementsForContainerReturnsItemsAndFolders() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item), .folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.elements(for: shareId)
        #expect(result != nil)
        #expect(result?.count == 2)
    }

    @Test("elements(for:) returns nil when container not found")
    func elementsForContainerReturnsNilWhenContainerNotFound() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.elements(for: "nonexistent-container")
        #expect(result == nil)
    }

    @Test("elements(for:) returns only items when no folders")
    func elementsForContainerReturnsOnlyItemsWhenNoFolders() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId, folderId: "folder-1")
        let item2 = ItemUiModel.mock(itemId: "item-2", shareId: shareId, folderId: "folder-1")
        let elements: [ShareContentElement] = [.item(item1), .item(item2)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.elements(for: "folder-1")
        #expect(result != nil)
        #expect(result?.count == 2)
        #expect(result?.allSatisfy { !$0.isFolder } == true)
    }

    // MARK: - folder(for:) Tests

    @Test("folder(for:) returns folder when found")
    func folderForIdReturnsFolder() {
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.folder(for: "folder-1")
        #expect(result != nil)
        #expect(result?.folderId == "folder-1")
    }

    @Test("folder(for:) returns nil when not found")
    func folderForIdReturnsNilWhenNotFound() {
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.folder(for: "nonexistent")
        #expect(result == nil)
    }

    // MARK: - items(in:) Tests

    @Test("items(in:) returns items in container")
    func itemsInContainerReturnsItems() {
        let item1 = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let item2 = ItemUiModel.mock(itemId: "item-2", shareId: shareId)
        let item3 = ItemUiModel.mock(itemId: "item-3", shareId: shareId, folderId: "folder-1")
        let elements: [ShareContentElement] = [.item(item1), .item(item2), .item(item3)]
        let content = ShareContent(share: share, elements: elements)

        let rootItems = content.items(in: shareId)
        #expect(rootItems != nil)
        #expect(rootItems?.count == 2)

        let folderItems = content.items(in: "folder-1")
        #expect(folderItems != nil)
        #expect(folderItems?.count == 1)
    }

    @Test("items(in:) returns nil when no items in container")
    func itemsInContainerReturnsNilWhenNoItems() {
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.items(in: "folder-1")
        #expect(result == nil)
    }

    // MARK: - folders(in:) Tests

    @Test("folders(in:) returns folders in container")
    func foldersInContainerReturnsFolders() {
        let folder1 = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let folder2 = FolderUiModel.mock(folderId: "folder-2", shareId: shareId)
        let folder3 = FolderUiModel.mock(folderId: "folder-3", shareId: shareId, parentFolderId: "folder-1")
        let elements: [ShareContentElement] = [.folder(folder1), .folder(folder2), .folder(folder3)]
        let content = ShareContent(share: share, elements: elements)

        let rootFolders = content.folders(in: shareId)
        #expect(rootFolders != nil)
        #expect(rootFolders?.count == 2)

        let nestedFolders = content.folders(in: "folder-1")
        #expect(nestedFolders != nil)
        #expect(nestedFolders?.count == 1)
    }

    @Test("folders(in:) returns nil when no folders in container")
    func foldersInContainerReturnsNilWhenNoFolders() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.folders(in: shareId)
        #expect(result == nil)
    }

    // MARK: - rootElements Tests

    @Test("rootElements returns elements at share level")
    func rootElementsReturnsElementsAtShareLevel() {
        let itemAtRoot = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let itemInFolder = ItemUiModel.mock(itemId: "item-2", shareId: shareId, folderId: "folder-1")
        let folderAtRoot = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(itemAtRoot), .item(itemInFolder), .folder(folderAtRoot)]
        let content = ShareContent(share: share, elements: elements)

        let rootElements = content.rootElements
        #expect(rootElements.count == 2)

        let rootIds = rootElements.map { $0.id }
        #expect(rootIds.contains(itemAtRoot.id))
        #expect(rootIds.contains("folder-1"))
        #expect(!rootIds.contains(itemInFolder.id))
    }

    @Test("rootElements returns empty when no root elements")
    func rootElementsReturnsCorrectElementsWhenOnlyFolderAtRoot() {
        let itemInFolder = ItemUiModel.mock(itemId: "item-1", shareId: shareId, folderId: "folder-1")
        let folder = FolderUiModel.mock(folderId: "folder-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(itemInFolder), .folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let rootElements = content.rootElements
        #expect(rootElements.count == 1)
        #expect(rootElements.first?.id == "folder-1")
    }

    // MARK: - flattenedItems(from:) Tests

    @Test("flattenedItems(from:) returns all nested items")
    func flattenedItemsFromContainerReturnsAllNestedItems() {
        // Structure:
        // root
        // ├─ item-A
        // └─ folder-F1
        //     ├─ item-B
        //     └─ folder-F2
        //         ├─ item-C
        //         └─ item-D

        let itemA = ItemUiModel.mock(itemId: "item-A", shareId: shareId)
        let itemB = ItemUiModel.mock(itemId: "item-B", shareId: shareId, folderId: "folder-F1")
        let itemC = ItemUiModel.mock(itemId: "item-C", shareId: shareId, folderId: "folder-F2")
        let itemD = ItemUiModel.mock(itemId: "item-D", shareId: shareId, folderId: "folder-F2")
        let folderF1 = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let folderF2 = FolderUiModel.mock(folderId: "folder-F2", shareId: shareId, parentFolderId: "folder-F1")

        let elements: [ShareContentElement] = [
            .item(itemA), .item(itemB), .item(itemC), .item(itemD),
            .folder(folderF1), .folder(folderF2)
        ]
        let content = ShareContent(share: share, elements: elements)

        // Flattened from root should include all items
        let flattenedFromRoot = content.flattenedItems(from: shareId)
        #expect(flattenedFromRoot.count == 4)

        // Flattened from folder-F1 should include items B, C, D
        let flattenedFromF1 = content.flattenedItems(from: "folder-F1")
        #expect(flattenedFromF1.count == 3)
        let f1ItemIds = flattenedFromF1.map { $0.itemId }
        #expect(f1ItemIds.contains("item-B"))
        #expect(f1ItemIds.contains("item-C"))
        #expect(f1ItemIds.contains("item-D"))

        // Flattened from folder-F2 should include items C, D only
        let flattenedFromF2 = content.flattenedItems(from: "folder-F2")
        #expect(flattenedFromF2.count == 2)
        let f2ItemIds = flattenedFromF2.map { $0.itemId }
        #expect(f2ItemIds.contains("item-C"))
        #expect(f2ItemIds.contains("item-D"))
    }

    @Test("flattenedItems(from:) returns empty for empty container")
    func flattenedItemsFromEmptyContainerReturnsEmpty() {
        let folder = FolderUiModel.mock(folderId: "empty-folder", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.flattenedItems(from: "empty-folder")
        #expect(result.isEmpty)
    }

    // MARK: - flattenedFolders(from:) Tests

    @Test("flattenedFolders(from:) returns all nested folders")
    func flattenedFoldersFromContainerReturnsAllNestedFolders() {
        // Structure:
        // root
        // └─ folder-F1
        //     └─ folder-F2
        //         └─ folder-F3

        let folderF1 = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let folderF2 = FolderUiModel.mock(folderId: "folder-F2", shareId: shareId, parentFolderId: "folder-F1")
        let folderF3 = FolderUiModel.mock(folderId: "folder-F3", shareId: shareId, parentFolderId: "folder-F2")

        let elements: [ShareContentElement] = [.folder(folderF1), .folder(folderF2), .folder(folderF3)]
        let content = ShareContent(share: share, elements: elements)

        // Flattened from root should return F1, F2, F3
        let flattenedFromRoot = content.flattenedFolders(from: shareId)
        #expect(flattenedFromRoot.count == 3)

        // Flattened from folder-F1 should return F2, F3
        let flattenedFromF1 = content.flattenedFolders(from: "folder-F1")
        #expect(flattenedFromF1.count == 2)
        let f1FolderIds = flattenedFromF1.map { $0.folderId }
        #expect(f1FolderIds.contains("folder-F2"))
        #expect(f1FolderIds.contains("folder-F3"))

        // Flattened from folder-F2 should return F3 only
        let flattenedFromF2 = content.flattenedFolders(from: "folder-F2")
        #expect(flattenedFromF2.count == 1)
        #expect(flattenedFromF2.first?.folderId == "folder-F3")
    }

    @Test("flattenedFolders(from:) returns empty for leaf folder")
    func flattenedFoldersFromLeafFolderReturnsEmpty() {
        let folder = FolderUiModel.mock(folderId: "leaf-folder", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let result = content.flattenedFolders(from: "leaf-folder")
        #expect(result.isEmpty)
    }

    // MARK: - getPathOfElement(containerId:) Tests

    @Test("getPathOfElement returns path from root to folder")
    func getPathOfElementReturnsPathFromRootToFolder() {
        // Structure:
        // root
        // └─ folder-F1
        //     └─ folder-F2
        //         └─ folder-F3

        let folderF1 = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let folderF2 = FolderUiModel.mock(folderId: "folder-F2", shareId: shareId, parentFolderId: "folder-F1")
        let folderF3 = FolderUiModel.mock(folderId: "folder-F3", shareId: shareId, parentFolderId: "folder-F2")

        let elements: [ShareContentElement] = [.folder(folderF1), .folder(folderF2), .folder(folderF3)]
        let content = ShareContent(share: share, elements: elements)

        // Path to folder-F3 should be [F1, F2, F3]
        let pathToF3 = content.getPathOfElement(containerId: "folder-F3")
        #expect(pathToF3.count == 3)
        #expect(pathToF3[0].folderId == "folder-F1")
        #expect(pathToF3[1].folderId == "folder-F2")
        #expect(pathToF3[2].folderId == "folder-F3")

        // Path to folder-F1 should be [F1]
        let pathToF1 = content.getPathOfElement(containerId: "folder-F1")
        #expect(pathToF1.count == 1)
        #expect(pathToF1[0].folderId == "folder-F1")
    }

    @Test("getPathOfElement returns empty for root")
    func getPathOfElementReturnsEmptyForRoot() {
        let folder = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let pathToRoot = content.getPathOfElement(containerId: shareId)
        #expect(pathToRoot.isEmpty)
    }

    @Test("getPathOfElement returns empty for nonexistent id")
    func getPathOfElementReturnsEmptyForNonexistentId() {
        let folder = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let elements: [ShareContentElement] = [.folder(folder)]
        let content = ShareContent(share: share, elements: elements)

        let path = content.getPathOfElement(containerId: "nonexistent")
        #expect(path.isEmpty)
    }

    // MARK: - Hashable & Identifiable Tests

    @Test("ShareContent is identifiable by share id")
    func shareContentIsIdentifiableByShareId() {
        let content = ShareContent(share: share, elements: [])
        #expect(content.id == share.id)
    }

    @Test("ShareContent hashable consistency")
    func shareContentHashableConsistency() {
        let item = ItemUiModel.mock(itemId: "item-1", shareId: shareId)
        let elements: [ShareContentElement] = [.item(item)]

        let content1 = ShareContent(share: share, elements: elements)
        let content2 = ShareContent(share: share, elements: elements)

        #expect(content1.hashValue == content2.hashValue)
    }

    // MARK: - Complex Hierarchy Tests

    @Test("Complex hierarchy with mixed content")
    func complexHierarchy() {
        // Structure:
        // root
        // ├─ item-A (regular)
        // ├─ item-B (alias)
        // ├─ item-C (with TOTP)
        // ├─ folder-F1
        // │   ├─ item-D
        // │   └─ folder-F2
        // │       └─ item-E (alias with TOTP)
        // └─ folder-F3 (empty)

        let itemA = ItemUiModel.mock(itemId: "item-A", shareId: shareId)
        let itemB = ItemUiModel.mock(itemId: "item-B", shareId: shareId, isAlias: true)
        let itemC = ItemUiModel.mock(itemId: "item-C", shareId: shareId, totpUri: "otpauth://totp/test")
        let itemD = ItemUiModel.mock(itemId: "item-D", shareId: shareId, folderId: "folder-F1")
        let itemE = ItemUiModel.mock(
            itemId: "item-E",
            shareId: shareId,
            folderId: "folder-F2",
            isAlias: true,
            totpUri: "otpauth://totp/test2"
        )

        let folderF1 = FolderUiModel.mock(folderId: "folder-F1", shareId: shareId)
        let folderF2 = FolderUiModel.mock(folderId: "folder-F2", shareId: shareId, parentFolderId: "folder-F1")
        let folderF3 = FolderUiModel.mock(folderId: "folder-F3", shareId: shareId)

        let elements: [ShareContentElement] = [
            .item(itemA), .item(itemB), .item(itemC), .item(itemD), .item(itemE),
            .folder(folderF1), .folder(folderF2), .folder(folderF3)
        ]
        let content = ShareContent(share: share, elements: elements)

        // Verify counts
        #expect(content.itemCount == 5)
        #expect(content.aliasCount == 2)
        #expect(content.totpCount == 2)

        // Verify root elements
        let rootElements = content.rootElements
        #expect(rootElements.count == 5) // A, B, C, F1, F3

        // Verify flattened items from F1
        let flattenedFromF1 = content.flattenedItems(from: "folder-F1")
        #expect(flattenedFromF1.count == 2) // D, E

        // Verify empty folder
        let f3Items = content.items(in: "folder-F3")
        #expect(f3Items == nil)
        let f3Folders = content.folders(in: "folder-F3")
        #expect(f3Folders == nil)

        // Verify path to F2
        let pathToF2 = content.getPathOfElement(containerId: "folder-F2")
        #expect(pathToF2.count == 2)
        #expect(pathToF2[0].folderId == "folder-F1")
        #expect(pathToF2[1].folderId == "folder-F2")
    }
}
