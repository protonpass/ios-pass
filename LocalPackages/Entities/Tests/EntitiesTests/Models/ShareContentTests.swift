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

//import Testing
//import EntitiesMocks
//@testable import Entities
//
//extension ItemUiModel {
//   static func mock(itemId:String, shareId: String) -> ItemUiModel {
//       ItemUiModel(itemId: itemId,
//                   shareId: shareId,
//                   type: .login,
//                   aliasEnabled: .random(),
//                   title: "Item title",
//                   description: "Itemn description",
//                   isAlias: .random(),
//                   totpUri: nil,
//                   lastUseTime: 123456678,
//                   modifyTime: 123456789,
//                   state: .active,
//                   pinned: true,
//                   isAliasEnabled: .random(),
//                   shared: true,
//                   hasEmail: true,
//                   hasUsername: true,
//                   hasPassword: true)
//    }
//}
//
//// MARK: - Tests
//
//@Suite("ShareContentIndex Tests")
//struct ShareContentTests {
//    let shareId = "share-1"
//    let share: Share
//
//    let itemUIa: ItemUiModel
//    let itemUIb: ItemUiModel
//    let itemUIc: ItemUiModel
//    let itemUId: ItemUiModel
//    
//    let folderUi1: FolderUiModel
//    let folderUi2: FolderUiModel
//    let folderUi3: FolderUiModel
//
//    let itemA: ShareContentElement
//    let itemB: ShareContentElement
//    let itemC: ShareContentElement
//    let itemD: ShareContentElement
//
//    let folderF3: ShareContentElement
//    let folderF2: ShareContentElement
//    let folderF1: ShareContentElement
//    let content: ShareContent
//    
//    
//    /*
//    root
//    ├─ item A
//    └─ folder F1
//        ├─ item B
//        └─ folder F2
//            └─ item C
//            └─ item D
//    └─ folder F3
//     
//     */
//    init() {
//        share = Share.random(shareID: shareId)
//        itemUIa = ItemUiModel.mock(itemId: "item-A", shareId: shareId)
//        itemUIb = ItemUiModel.mock(itemId: "item-B", shareId: shareId)
//        itemUIc = ItemUiModel.mock(itemId: "item-C", shareId: shareId)
//        itemUId = ItemUiModel.mock(itemId: "item-D", shareId: shareId)
//
//  
//         folderUi3 =    FolderUiModel(
//            folderId: "folder-F3",
//            shareId: share.id,
//            parentId: nil,
//            content: []
//        )
//        
//        itemA = .item(
//            itemUIa
//        )
//        itemB = .item(
//            itemUIb
//        )
//        itemC = .item(
//            itemUIc
//        )
//        itemD = .item(
//            itemUId
//        )
//        
//        folderUi2 =   FolderUiModel(
//           folderId: "folder-F2",
//           shareId: share.id,
//           parentId: "folder-F1",
//           content: [itemC, itemD]
//       )
//        
//        folderF2 = .folder(
//            folderUi2
//        )
//        
//        folderF3 = .folder(
//            folderUi3
//        )
//        folderUi1 = FolderUiModel(
//           folderId: "folder-F1",
//           shareId: share.id,
//           parentId: nil,
//           content: [itemB, folderF2]
//       )
//        
//        folderF1 = .folder(
//            folderUi1
//        )
//        content =  ShareContent(
//            share: share,
//            elements: [itemA, folderF1, folderF3]
//        )
//    }
//
//    // MARK: - Index presence
//
//    @Test("Index contains all elements")
//    func indexContainsAllElements() {
//        #expect(content.contains(itemA.id))
//        #expect(content.contains(itemB.id))
//        #expect(content.contains(itemC.id))
//        #expect(content.contains(folderF1.id))
//        #expect(content.contains(folderF2.id))
//    }
//
//    // MARK: - Element lookup
//    
//    @Test("Element lookup returns correct element")
//    func elementLookup() throws {
//        let itemElement1 = content.element(for: itemB.id)
//        #expect(itemElement1?.isFolder == false)
//        #expect(itemElement1?.id == itemB.id)
//        #expect(itemElement1 == itemB)
//        
//        let itemElement2 = content.element(for: itemA.id)
//        #expect(itemElement2?.isFolder == false)
//        #expect(itemElement2?.id == itemA.id)
//        #expect(itemElement2 == itemA)
//
//        let folderElement = content.element(for: folderF1.id)
//        #expect(folderElement?.isFolder == true)
//        #expect(folderElement?.id == folderF1.id)
//        #expect(folderElement == folderF1)
//        #expect(folderElement?.content == [itemB, folderF2])
//        
//        var rootElements = content.elements(for: share.id)
//        let unwrappedRootElements = try #require(rootElements)
//        #expect(unwrappedRootElements.count == 3)
//        #expect(unwrappedRootElements.contains([itemA, folderF1, folderF3]))
//    }
//    
//    @Test("Get all items of share")
//    func allItemsLookup() {
//        #expect(content.itemCount == 4)
//        #expect(content.items.contains([itemUIa, itemUIb, itemUIc, itemUId]))
//    }
//    
//    @Test("Get content per folder")
//    func itemsForFolderLookup() {
//        //root
//        #expect(content.items(in: share.id) == [itemUIa])
//        #expect(content.folders(in: share.id) == [folderUi1, folderUi3])
//        //Folder 1
//        #expect(content.items(in: folderF1.id) == [itemUIb])
//        #expect(content.folders(in:  folderF1.id) == [folderUi2])
//        
//        //Folder 2
//        #expect(content.items(in: folderF2.id) == [itemUIc, itemUId])
//        #expect(content.folders(in:  folderF2.id).isEmpty)
//    }
//}
