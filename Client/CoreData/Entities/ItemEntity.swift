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

@objc(ItemEntity)
public class ItemEntity: NSManagedObject {}

extension ItemEntity: Identifiable {}

extension ItemEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<ItemEntity> {
        NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
    }

    @NSManaged var aliasEmail: String?
    @NSManaged var content: String?
    @NSManaged var contentFormatVersion: Int16
    @NSManaged var createTime: Int64
    /// Is a custom field. Whether the type of item is log in or not
    @NSManaged var isLogInItem: Bool
    @NSManaged var itemID: String?
    @NSManaged var itemKeySignature: String?
    /// Is a custom field. The time interval since 1970 of the moment the item is last used in auto filling context
    @NSManaged var lastUsedTime: Int64
    @NSManaged var modifyTime: Int64
    @NSManaged var revision: Int16
    @NSManaged var revisionTime: Int64
    @NSManaged var rotationID: String?
    @NSManaged var shareID: String?
    @NSManaged var signatureEmail: String?
    @NSManaged var state: Int16
    /// Is a custom field. The exact protobuf structure but have the content symmetrically encrypted
    @NSManaged var symmetricallyEncryptedContent: String?
    @NSManaged var userSignature: String?
}

extension ItemEntity {
    func toEncryptedItem(shareId: String) throws -> SymmetricallyEncryptedItem {
        guard let itemID else {
            throw CoreDataError.corrupted(object: self, property: "itemID")
        }

        guard let rotationID else {
            throw CoreDataError.corrupted(object: self, property: "rotationID")
        }

        guard let symmetricallyEncryptedContent else {
            throw CoreDataError.corrupted(object: self, property: "symmetricallyEncryptedContent")
        }

        guard let content else {
            throw CoreDataError.corrupted(object: self, property: "content")
        }

        guard let userSignature else {
            throw CoreDataError.corrupted(object: self, property: "userSignature")
        }

        guard let itemKeySignature else {
            throw CoreDataError.corrupted(object: self, property: "itemKeySignature")
        }

        guard let signatureEmail else {
            throw CoreDataError.corrupted(object: self, property: "signatureEmail")
        }

        let itemRevision = ItemRevision(itemID: itemID,
                                        revision: revision,
                                        contentFormatVersion: contentFormatVersion,
                                        rotationID: rotationID,
                                        content: content,
                                        userSignature: userSignature,
                                        itemKeySignature: itemKeySignature,
                                        state: state,
                                        signatureEmail: signatureEmail,
                                        aliasEmail: aliasEmail,
                                        createTime: createTime,
                                        modifyTime: modifyTime,
                                        revisionTime: revisionTime)

        return .init(shareId: shareId,
                     item: itemRevision,
                     encryptedContent: symmetricallyEncryptedContent,
                     lastUsedTime: lastUsedTime,
                     isLogInItem: isLogInItem)
    }

    func hydrate(from item: SymmetricallyEncryptedItem,
                 lastUsedTime: Int64? = nil) {
        self.itemID = item.item.itemID
        self.revision = item.item.revision
        self.contentFormatVersion = item.item.contentFormatVersion
        self.rotationID = item.item.rotationID
        self.content = item.item.content
        self.symmetricallyEncryptedContent = item.encryptedContent
        self.userSignature = item.item.userSignature
        self.itemKeySignature = item.item.itemKeySignature
        self.state = item.item.state
        self.signatureEmail = item.item.signatureEmail
        self.aliasEmail = item.item.aliasEmail
        self.createTime = item.item.createTime
        self.modifyTime = item.item.modifyTime
        self.shareID = item.shareId
        self.isLogInItem = item.isLogInItem
        if let lastUsedTime {
            self.lastUsedTime = lastUsedTime
        }
    }
}
