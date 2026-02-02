//  
// FolderUiModel+Mock.swift
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

import Foundation
import Entities

public extension FolderUiModel {
    static func mock(
        folderId: String,
        shareId: String,
        parentFolderId: String? = nil
    ) -> FolderUiModel {
        let folder = Folder(
            vaultID: shareId,
            folderID: folderId,
            parentFolderID: parentFolderId,
            keyRotation: 1,
            folderKey: "key",
            contentFormatVersion: 1,
            content: "content"
        )
        return FolderUiModel(
            shareId: shareId,
            folder: folder,
            content: FolderContent(name: "Folder \(folderId)")
        )
    }
}
