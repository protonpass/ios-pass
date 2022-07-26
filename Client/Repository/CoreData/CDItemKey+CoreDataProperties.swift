//
// CDItemKey+CoreDataProperties.swift
// Proton Pass - Created on 18/07/2022.
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

extension CDItemKey {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<CDItemKey> {
        NSFetchRequest<CDItemKey>(entityName: "CDItemKey")
    }

    @NSManaged var createTime: Int64
    @NSManaged var key: String?
    @NSManaged var keyPassphrase: String?
    @NSManaged var keySignature: String?
    @NSManaged var rotationID: String?
    @NSManaged var shareID: String?
    @NSManaged var share: CDShare?
}

extension CDItemKey: Identifiable {}

extension CDItemKey {
    class func allItemKeysFetchRequest(shareId: String) -> NSFetchRequest<CDItemKey> {
        let fetchRequest = fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %s", shareId)
        return fetchRequest
    }
}

extension CDItemKey {
    func toItemKey() throws -> ItemKey {
        guard let rotationID = rotationID else {
            throw CoreDataError.corruptedObject(self, "rotationID")
        }

        guard let key = key else {
            throw CoreDataError.corruptedObject(self, "key")
        }

        guard let keySignature = keySignature else {
            throw CoreDataError.corruptedObject(self, "keySignature")
        }

        return .init(rotationID: rotationID,
                     key: key,
                     keyPassphrase: keyPassphrase,
                     keySignature: keySignature,
                     createTime: Int(createTime))
    }
}
