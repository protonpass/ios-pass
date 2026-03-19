//
// FolderEntity.swift
// Proton Pass - Created on 01/12/2025.
// Copyright (c) 2025 Proton Technologies AG
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

@objc(FolderEntity)
final class FolderEntity: NSManagedObject {}

extension FolderEntity: Identifiable {}

extension FolderEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<FolderEntity> {
        NSFetchRequest<FolderEntity>(entityName: "FolderEntity")
    }

    @NSManaged var shareID: String
    @NSManaged var userID: String
    @NSManaged var folderID: String
    @NSManaged var vaultID: String
    @NSManaged var parentFolderID: String?
    @NSManaged var keyRotation: Int64
    @NSManaged var folderKey: String
    @NSManaged var contentFormatVersion: Int64
    @NSManaged var content: String
    @NSManaged var symmetricallyEncryptedContent: String
}

extension FolderEntity {
    func toEncryptedFolder() -> SymmetricallyEncryptedFolder {
        let folder = Folder(vaultID: vaultID,
                            folderID: folderID,
                            parentFolderID: parentFolderID,
                            keyRotation: keyRotation,
                            folderKey: folderKey,
                            contentFormatVersion: Int(contentFormatVersion),
                            content: content)

        return SymmetricallyEncryptedFolder(shareId: shareID,
                                            userId: userID,
                                            folder: folder,
                                            encryptedContent: symmetricallyEncryptedContent)
    }

    func hydrate(from encryptedFolder: SymmetricallyEncryptedFolder) {
        shareID = encryptedFolder.shareId
        userID = encryptedFolder.userId
        folderID = encryptedFolder.folderId
        vaultID = encryptedFolder.folder.vaultID
        parentFolderID = encryptedFolder.folder.parentFolderID
        keyRotation = encryptedFolder.folder.keyRotation
        folderKey = encryptedFolder.folder.folderKey
        contentFormatVersion = Int64(encryptedFolder.folder.contentFormatVersion)
        content = encryptedFolder.folder.content
        symmetricallyEncryptedContent = encryptedFolder.encryptedContent
    }
}
