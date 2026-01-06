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
    public var id: String { folderId + shareId }
    public let folderId: String
    public let parentId: String
    public let shareId: String
    public let content: [ShareContentElement]
    
    public let precomputedHash: Int
    
    public init(folderId: String, shareId: String, parentId: String?, content: [ShareContentElement]) {
        self.folderId = folderId
        self.shareId = shareId
        self.parentId = parentId ?? shareId
        self.content = content
        var hasher = Hasher()
        hasher.combine(folderId)
        hasher.combine(parentId)
        hasher.combine(shareId)
        hasher.combine(content)
        precomputedHash = hasher.finalize()
    }
}
