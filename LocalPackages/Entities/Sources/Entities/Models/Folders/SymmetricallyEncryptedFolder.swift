//
// SymmetricallyEncryptedFolder.swift
// Proton Pass - Created on 02/12/2025.
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

import Foundation

// TODO: ItemIdentifiable need to evolve
/// ItemRevision with its symmetrically encrypted content by an application-wide symmetric key
public struct SymmetricallyEncryptedFolder: Equatable, Sendable, Hashable {
    /// ID of the share that the item belongs to
    public let shareId: String

    public var folderId: String { folder.folderID }

    public var userId: String

    /// Original item revision object as returned by the server
    public let folder: Folder

    /// Symmetrically encrypted content in base 64 format
    public let encryptedContent: String

    public init(shareId: String,
                userId: String,
                folder: Folder,
                encryptedContent: String) {
        self.shareId = shareId
        self.folder = folder
        self.userId = userId
        self.encryptedContent = encryptedContent
    }
}

public protocol ElementIdentifiable: Sendable, Equatable, CustomDebugStringConvertible {
    var shareId: String { get }
    var elementId: String { get }
}

extension SymmetricallyEncryptedFolder: ElementIdentifiable {
    public var elementId: String {
        folderId
    }

    public var debugDescription: String {
        "Element \(elementId) - Share \(shareId)"
    }
}
