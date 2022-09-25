//
// ItemRevisionEntity.swift
// Proton Pass - Created on 10/08/2022.
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
import Foundation

@objc(ItemRevisionEntity)
public class ItemRevisionEntity: NSManagedObject {}

extension ItemRevisionEntity: Identifiable {}

extension ItemRevisionEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<ItemRevisionEntity> {
        NSFetchRequest<ItemRevisionEntity>(entityName: "ItemRevisionEntity")
    }

    @NSManaged var aliasEmail: String?
    @NSManaged var content: String?
    @NSManaged var contentFormatVersion: Int16
    @NSManaged var createTime: Int64
    @NSManaged var itemID: String?
    @NSManaged var itemKeySignature: String?
    @NSManaged var modifyTime: Int64
    @NSManaged var revision: Int16
    @NSManaged var revisionTime: Int64
    @NSManaged var rotationID: String?
    @NSManaged var shareID: String?
    @NSManaged var signatureEmail: String?
    @NSManaged var state: Int16
    @NSManaged var userSignature: String?
}

extension ItemRevisionEntity {
    func toItemRevision() throws -> ItemRevision {
        guard let itemID = itemID else {
            throw CoreDataError.corrupted(object: self, property: "itemID")
        }

        guard let rotationID = rotationID else {
            throw CoreDataError.corrupted(object: self, property: "rotationID")
        }

        guard let content = content else {
            throw CoreDataError.corrupted(object: self, property: "content")
        }

        guard let userSignature = userSignature else {
            throw CoreDataError.corrupted(object: self, property: "userSignature")
        }

        guard let itemKeySignature = itemKeySignature else {
            throw CoreDataError.corrupted(object: self, property: "itemKeySignature")
        }

        guard let signatureEmail = signatureEmail else {
            throw CoreDataError.corrupted(object: self, property: "signatureEmail")
        }

        return .init(itemID: itemID,
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
    }

    func hydrate(from item: ItemRevision,
                 shareId: String) {
        self.itemID = item.itemID
        self.revision = item.revision
        self.contentFormatVersion = item.contentFormatVersion
        self.rotationID = item.rotationID
        self.content = item.content
        self.userSignature = item.userSignature
        self.itemKeySignature = item.itemKeySignature
        self.state = item.state
        self.signatureEmail = item.signatureEmail
        self.aliasEmail = item.aliasEmail
        self.createTime = item.createTime
        self.modifyTime = item.modifyTime
        self.shareID = shareId
    }
}
