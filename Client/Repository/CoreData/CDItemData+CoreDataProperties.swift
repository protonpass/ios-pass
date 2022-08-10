//
// CDItemData+CoreDataProperties.swift
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

extension CDItemData {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<CDItemData> {
        NSFetchRequest<CDItemData>(entityName: "CDItemData")
    }

    @NSManaged var aliasEmail: String?
    @NSManaged var content: String?
    @NSManaged var contentFormatVersion: Int16
    @NSManaged var createTime: Int64
    @NSManaged var itemID: String?
    @NSManaged var itemKeySignature: String?
    @NSManaged var modifyTime: Int64
    @NSManaged var revision: Int16
    @NSManaged var rotationID: String?
    @NSManaged var shareID: String?
    @NSManaged var signatureEmail: String?
    @NSManaged var state: Int16
    @NSManaged var userSignature: String?
}

extension CDItemData: Identifiable {}

extension CDItemData {
    func toItemData() throws -> ItemData {
        guard let itemID = itemID else {
            throw CoreDataError.corruptedObject(self, "itemID")
        }

        guard let rotationID = rotationID else {
            throw CoreDataError.corruptedObject(self, "rotationID")
        }

        guard let content = content else {
            throw CoreDataError.corruptedObject(self, "content")
        }

        guard let userSignature = userSignature else {
            throw CoreDataError.corruptedObject(self, "userSignature")
        }

        guard let itemKeySignature = itemKeySignature else {
            throw CoreDataError.corruptedObject(self, "itemKeySignature")
        }

        guard let signatureEmail = signatureEmail else {
            throw CoreDataError.corruptedObject(self, "signatureEmail")
        }

        guard let aliasEmail = aliasEmail else {
            throw CoreDataError.corruptedObject(self, "aliasEmail")
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
                     modifyTime: modifyTime)
    }
}

extension CDItemData {
    func copy(from itemData: ItemData, shareId: String) {
        self.itemID = itemData.itemID
        self.revision = itemData.revision
        self.contentFormatVersion = itemData.contentFormatVersion
        self.rotationID = itemData.rotationID
        self.content = itemData.content
        self.userSignature = itemData.userSignature
        self.itemKeySignature = itemData.itemKeySignature
        self.state = itemData.state
        self.signatureEmail = itemData.signatureEmail
        self.aliasEmail = itemData.aliasEmail
        self.createTime = itemData.createTime
        self.modifyTime = itemData.modifyTime
        self.shareID = shareId
    }
}
