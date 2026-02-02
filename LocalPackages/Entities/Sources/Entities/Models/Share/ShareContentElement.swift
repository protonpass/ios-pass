//
// ShareContentElement.swift
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

public enum ShareContentElement: Sendable, Equatable, Hashable, Identifiable {
    case item(ItemUiModel)
    case folder(FolderUiModel)

    public var id: String {
        switch self {
        case let .item(content): content.id
        case let .folder(folder): folder.folderId
        }
    }

    public var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }

    public var shareId: String {
        switch self {
        case let .item(item): item.shareId
        case let .folder(folder): folder.shareId
        }
    }

    public var itemValue: ItemUiModel? {
        if case let .item(item) = self { return item }
        return nil
    }

    public var folderValue: FolderUiModel? {
        if case let .folder(folder) = self { return folder }
        return nil
    }

    public var shared: Bool {
        if case let .item(item) = self { return item.shared }
        return false
    }

    public var containerId: String {
        switch self {
        case let .item(item): item.parentId
        case let .folder(folder): folder.parentId
        }
    }
}
