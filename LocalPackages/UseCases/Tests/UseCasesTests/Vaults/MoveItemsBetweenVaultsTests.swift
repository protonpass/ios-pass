//
// MoveItemsBetweenVaultsTests.swift
// Proton Pass - Created on 21/05/2026.
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

@testable import UseCases
import Client
import ClientMocks
import Entities
import EntitiesMocks
import Foundation
import Testing

@MainActor
struct MoveItemsBetweenVaultsTests {
    private let repository: ItemRepositoryProtocolMock
    private let appContentManager: AppContentManagerProtocolMock
    private let sut: MoveItemsBetweenContainers
    private let sourceShareId = "share-A"
    private let destinationShareId = "share-B"

    init() {
        repository = ItemRepositoryProtocolMock()
        appContentManager = AppContentManagerProtocolMock()
        sut = MoveItemsBetweenContainers(repository: repository,
                                         appContentManager: appContentManager)
    }

    // MARK: - .allItemsInFolder

    @Test
    func `allItemsInFolder calls repository.move with the folder's direct items`() async throws {
        let folder = FolderUiModel.mock(folderId: "F1", shareId: sourceShareId)
        let item1 = ItemUiModel.mock(itemId: "I1", shareId: sourceShareId, folderId: "F1")
        let item2 = ItemUiModel.mock(itemId: "I2", shareId: sourceShareId, folderId: "F1")
        appContentManager.stubbedGetShareContentResult = ShareContent(share: .random(shareID: sourceShareId),
                                                                      elements: [
                                                                          .folder(folder),
                                                                          .item(item1),
                                                                          .item(item2)
                                                                      ])

        try await sut.execute(context: .allItemsInFolder(folder),
                              to: destinationShareId,
                              destinationFolderId: "F-dest")

        #expect(repository.invokedMoveCount == 1)
        let args = try #require(repository.invokedMoveParameters)
        #expect(args.items.map(\.itemId).sorted() == ["I1", "I2"])
        #expect(args.toShareId == destinationShareId)
        #expect(args.destinationFolderId == "F-dest")
    }

    @Test
    func `allItemsInFolder leaves items of subfolders in place`() async throws {
        // Hierarchy: F-root (direct item I-direct)
        //   |__ F-child (item I-nested)
        //         |__ F-grandchild (item I-deep)
        let root = FolderUiModel.mock(folderId: "F-root", shareId: sourceShareId)
        let child = FolderUiModel.mock(folderId: "F-child", shareId: sourceShareId, parentFolderId: "F-root")
        let grandchild = FolderUiModel.mock(folderId: "F-grandchild",
                                            shareId: sourceShareId,
                                            parentFolderId: "F-child")
        let direct = ItemUiModel.mock(itemId: "I-direct", shareId: sourceShareId, folderId: "F-root")
        let nested = ItemUiModel.mock(itemId: "I-nested", shareId: sourceShareId, folderId: "F-child")
        let deep = ItemUiModel.mock(itemId: "I-deep", shareId: sourceShareId, folderId: "F-grandchild")

        appContentManager.stubbedGetShareContentResult = ShareContent(share: .random(shareID: sourceShareId),
                                                                      elements: [
                                                                          .folder(root), .folder(child),
                                                                          .folder(grandchild),
                                                                          .item(direct), .item(nested), .item(deep)
                                                                      ])

        try await sut.execute(context: .allItemsInFolder(root),
                              to: destinationShareId,
                              destinationFolderId: nil)

        let args = try #require(repository.invokedMoveParameters)
        #expect(args.items.map(\.itemId) == ["I-direct"])
        #expect(args.destinationFolderId == nil)
        #expect(args.toShareId == destinationShareId)
    }

    @Test
    func `allItemsInFolder with an empty folder does not call the repository`() async throws {
        let folder = FolderUiModel.mock(folderId: "F-empty", shareId: sourceShareId)
        appContentManager.stubbedGetShareContentResult = ShareContent(share: .random(shareID: sourceShareId),
                                                                      elements: [.folder(folder)])

        try await sut.execute(context: .allItemsInFolder(folder),
                              to: destinationShareId,
                              destinationFolderId: nil)

        #expect(repository.invokedMoveCount == 0)
    }

    @Test
    func `allItemsInFolder with no share content does not call the repository`() async throws {
        let folder = FolderUiModel.mock(folderId: "F1", shareId: sourceShareId)
        appContentManager.stubbedGetShareContentResult = nil

        try await sut.execute(context: .allItemsInFolder(folder),
                              to: destinationShareId,
                              destinationFolderId: nil)

        #expect(repository.invokedMoveCount == 0)
    }

    // MARK: - .allItems

    @Test
    func `allItems leaves items of folders in place`() async throws {
        let vault = Share.random(shareID: sourceShareId)
        let folder = FolderUiModel.mock(folderId: "F1", shareId: sourceShareId)
        let root = ItemUiModel.mock(itemId: "I-root", shareId: sourceShareId, folderId: nil)
        let inFolder = ItemUiModel.mock(itemId: "I-in-folder", shareId: sourceShareId, folderId: "F1")
        appContentManager.stubbedGetShareContentResult = ShareContent(share: vault,
                                                                      elements: [
                                                                          .folder(folder),
                                                                          .item(root),
                                                                          .item(inFolder)
                                                                      ])

        try await sut.execute(context: .allItems(vault),
                              to: destinationShareId,
                              destinationFolderId: "F-dest")

        let args = try #require(repository.invokedMoveParameters)
        #expect(args.items.map(\.itemId) == ["I-root"])
        #expect(args.toShareId == destinationShareId)
        #expect(args.destinationFolderId == "F-dest")
    }

    @Test
    func `allItems with items only in folders does not call the repository`() async throws {
        let vault = Share.random(shareID: sourceShareId)
        let folder = FolderUiModel.mock(folderId: "F1", shareId: sourceShareId)
        let inFolder = ItemUiModel.mock(itemId: "I-in-folder", shareId: sourceShareId, folderId: "F1")
        appContentManager.stubbedGetShareContentResult = ShareContent(share: vault,
                                                                      elements: [
                                                                          .folder(folder),
                                                                          .item(inFolder)
                                                                      ])

        try await sut.execute(context: .allItems(vault),
                              to: destinationShareId,
                              destinationFolderId: nil)

        #expect(repository.invokedMoveCount == 0)
    }

    @Test
    func `allItems with no share content does not call the repository`() async throws {
        appContentManager.stubbedGetShareContentResult = nil

        try await sut.execute(context: .allItems(.random(shareID: sourceShareId)),
                              to: destinationShareId,
                              destinationFolderId: nil)

        #expect(repository.invokedMoveCount == 0)
    }
}
