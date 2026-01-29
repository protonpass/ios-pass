//
// FolderUiModel.swift
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

import Foundation

public struct FolderUiModel: PrecomputedHashable, Equatable, Sendable, Identifiable {
    // Existing properties
    public var id: String { folderId }
    public let folderId: String
    public let parentId: String
    public let shareId: String
    public let lastUseTime: Int64?
    public let folder: Folder
    public let content: FolderContent

    public let precomputedHash: Int

    public init(shareId: String, folder: Folder, content: FolderContent, lastUseTime: Int64? = nil) {
        folderId = folder.folderID
        self.shareId = shareId
        parentId = folder.parentFolderID ?? shareId
        self.lastUseTime = lastUseTime
        self.content = content
        self.folder = folder
        var hasher = Hasher()
        hasher.combine(folderId)
        hasher.combine(parentId)
        hasher.combine(shareId)
        hasher.combine(lastUseTime)
        hasher.combine(content)
        hasher.combine(folder)
        precomputedHash = hasher.finalize()
    }

    var isRootFolder: Bool {
        parentId == shareId
    }
}
