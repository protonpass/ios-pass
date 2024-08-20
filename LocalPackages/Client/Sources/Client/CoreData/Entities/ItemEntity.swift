//
// ItemEntity.swift
// Proton Pass - Created on 20/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import CoreData
import Entities

@objc(ItemEntity)
final class ItemEntity: NSManagedObject {}

extension ItemEntity: Identifiable {}

extension ItemEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<ItemEntity> {
        NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
    }

    @NSManaged var aliasEmail: String?
    @NSManaged var content: String?
    @NSManaged var contentFormatVersion: Int64
    @NSManaged var createTime: Int64
    @NSManaged var isLogInItem: Bool // Custom field
    @NSManaged var itemID: String
    @NSManaged var itemKey: String?
    @NSManaged var keyRotation: Int64
    @NSManaged var lastUseTime: Int64
    @NSManaged var modifyTime: Int64
    @NSManaged var revision: Int64
    @NSManaged var revisionTime: Int64
    @NSManaged var shareID: String // Custom field
    @NSManaged var state: Int64
    @NSManaged var pinned: Bool
    @NSManaged var pinTime: Int64
    @NSManaged var symmetricallyEncryptedContent: String? // Custom field
    @NSManaged var flags: Int64
    @NSManaged var userID: String
}

extension ItemEntity {
    func toEncryptedItem() throws -> SymmetricallyEncryptedItem {
//        guard let shareID else {
//            throw PassError.coreData(.corrupted(object: self, property: "shareID"))
//        }
//
//        guard let itemID else {
//            throw PassError.coreData(.corrupted(object: self, property: "itemID"))
//        }

        guard let symmetricallyEncryptedContent else {
            throw PassError.coreData(.corrupted(object: self,
                                                property: "symmetricallyEncryptedContent"))
        }

        guard let content else {
            throw PassError.coreData(.corrupted(object: self, property: "content"))
        }

        let item = Item(itemID: itemID,
                        revision: revision,
                        contentFormatVersion: contentFormatVersion,
                        keyRotation: keyRotation,
                        content: content,
                        itemKey: itemKey,
                        state: state,
                        pinned: pinned,
                        pinTime: pinTime == 0 ? nil : Int(pinTime),
                        aliasEmail: aliasEmail,
                        createTime: createTime,
                        modifyTime: modifyTime,
                        lastUseTime: lastUseTime == 0 ? nil : lastUseTime,
                        revisionTime: revisionTime,
                        flags: Int(flags))

        return .init(shareId: shareID,
                     userId: userID,
                     item: item,
                     encryptedContent: symmetricallyEncryptedContent,
                     isLogInItem: isLogInItem)
    }

    func hydrate(from symmetricallyEncryptedItem: SymmetricallyEncryptedItem) {
        let item = symmetricallyEncryptedItem.item
        aliasEmail = item.aliasEmail
        content = item.content
        contentFormatVersion = item.contentFormatVersion
        createTime = item.createTime
        isLogInItem = symmetricallyEncryptedItem.isLogInItem
        itemID = item.itemID
        itemKey = item.itemKey
        keyRotation = item.keyRotation
        lastUseTime = item.lastUseTime ?? 0
        modifyTime = item.modifyTime
        pinned = item.pinned
        revision = item.revision
        revisionTime = item.revisionTime
        shareID = symmetricallyEncryptedItem.shareId
        userID = symmetricallyEncryptedItem.userId
        state = item.state
        symmetricallyEncryptedContent = symmetricallyEncryptedItem.encryptedContent
        flags = Int64(item.flags)
    }
}
