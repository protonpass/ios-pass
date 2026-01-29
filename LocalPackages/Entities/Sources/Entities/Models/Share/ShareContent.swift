//
// ShareContent.swift
// Proton Pass - Created on 03/10/2023.
// Copyright (c) 2023 Proton Technologies AG
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

// public typealias ContainerId = String
//
// public struct ShareContent: Identifiable, Hashable, Sendable {
//    public let share: Share
//
//    private let content: [ContainerId: [ShareContentElement]]
//
//    private let itemsByContainer: [ContainerId: [ShareContentElement]]
//    private let foldersByContainer: [ContainerId: [ShareContentElement]]
//    public let itemCount: Int
//    public let aliasCount: Int
//    public let totpCount: Int
//
//    public var id: String {
//        share.id
//    }
//
//    public init(share: Share, elements: [ShareContentElement]) {
//        self.share = share
//
//        var itemCount = 0
//        var aliasCount = 0
//        var totpCount = 0
//        var content = [ContainerId: [ShareContentElement]]()
//        var itemsByContainer = [ContainerId: [ShareContentElement]]()
//        var foldersByContainer = [ContainerId: [ShareContentElement]]()
//        for element in elements {
//            content[element.containerId, default: []].append(element)
//            if case let .item(item) = element {
//                itemCount += 1
//                aliasCount += item.isAlias ? 1 : 0
//                totpCount += item.hasTotpUri ? 1 : 0
//            }
//
//            switch element {
//            case .item:
//                itemsByContainer[element.containerId, default: []].append(element)
//
//            case .folder:
//                foldersByContainer[element.containerId, default: []].append(element)
//            }
//        }
//        self.itemCount = itemCount
//        self.aliasCount = aliasCount
//        self.totpCount = totpCount
//        self.content = content
//        self.itemsByContainer = itemsByContainer
//        self.foldersByContainer = foldersByContainer
//        if !foldersByContainer.isEmpty {
//            print("woot")
//        }
//    }
// }
//
// public extension ShareContent {
//    var allElements: [ShareContentElement] {
//        var result: [ShareContentElement] = []
//        result.reserveCapacity(content.values.reduce(0) { $0 + $1.count })
//
//        for bucket in content.values {
//            result.append(contentsOf: bucket)
//        }
//
//        return result
//    }
//
//    var allItems: [ItemUiModel] {
//        var result: [ItemUiModel] = []
//        result.reserveCapacity(itemsByContainer.values.reduce(0) { $0 + $1.count })
//
//        for bucket in content.values {
//            for element in bucket {
//                if case let .item(item) = element {
//                    result.append(item)
//                }
//            }
//        }
//
//        return result
//    }
//
//    var allFolders: [FolderUiModel] {
//        var result: [FolderUiModel] = []
//        result.reserveCapacity(foldersByContainer.values.reduce(0) { $0 + $1.count })
//
//        for bucket in content.values {
//            for element in bucket {
//                if case let .folder(folder) = element {
//                    result.append(folder)
//                }
//            }
//        }
//
//        return result
//    }
//
//    func element(in containerId: String, for id: String) -> ShareContentElement? {
//        content[containerId]?.first { $0.id == id }
//    }
//
//    func elements(for containerId: String) -> [ShareContentElement]? {
//        content[containerId]
//    }
//
//    func folder(for id: String) -> FolderUiModel? {
//        allFolders.first { $0.id == id }
//    }
//
//    func flattenedItems(from containerId: String) -> [ItemUiModel] {
//        var items = itemsByContainer[containerId]?.compactMap(\.itemValue) ?? []
//
//        if let folders = foldersByContainer[containerId] {
//            for folder in folders {
//                if let folderModel = folder.folderValue {
//                    items.append(contentsOf: flattenedItems(from: folderModel.folderId))
//                }
//            }
//        }
//
//        return items
//    }
//
//    func flattenedFolders(from containerId: String) -> [FolderUiModel] {
//        var folders = foldersByContainer[containerId]?.compactMap(\.folderValue) ?? []
//
//        let directFolders = folders
//        for folder in directFolders {
//            folders.append(contentsOf: flattenedFolders(from: folder.folderId))
//        }
//
//        return folders
//    }
//
//    func items(in containerId: String) -> [ItemUiModel]? {
//        itemsByContainer[containerId]?.compactMap(\.itemValue)
//    }
//
//    func folders(in containerId: String) -> [FolderUiModel]? {
//        foldersByContainer[containerId]?.compactMap(\.folderValue)
//    }
//
//    var rootElements: [ShareContentElement] {
//        content[share.id] ?? []
//    }
//
//    func getPath(forElementWithContainer id: String) -> [FolderUiModel] {
//        var path: [FolderUiModel] = []
//        var containerId: String? = id
//        while let currentId = containerId, let folder = folder(for: currentId) {
//            path.insert(folder, at: 0)
//            containerId = folder.isRootFolder ? nil : folder.parentId
//        }
//        return path
//    }
// }
//
// public enum ShareContentElement: Sendable, Equatable, Hashable, Identifiable {
//    case item(ItemUiModel)
//    case folder(FolderUiModel)
//
//    public var id: String {
//        switch self {
//        case let .item(content):
//            content.id
//        case let .folder(folder):
//            folder.folderId
//        }
//    }
//
//    public var isFolder: Bool {
//        switch self {
//        case .folder:
//            true
//        default:
//            false
//        }
//    }
//
//    public var shareId: String {
//        switch self {
//        case let .item(item):
//            item.shareId
//        case let .folder(folder):
//            folder.shareId
//        }
//    }
//
//    public var itemValue: ItemUiModel? {
//        switch self {
//        case let .item(item):
//            item
//        default:
//            nil
//        }
//    }
//
//    public var folderValue: FolderUiModel? {
//        switch self {
//        case let .folder(folder):
//            folder
//        default:
//            nil
//        }
//    }
//
//    public var shared: Bool {
//        switch self {
//        case let .item(item):
//            item.shared
//        case .folder:
//            false
//        }
//    }
//
//    public var containerId: String {
//        switch self {
//        case let .item(item):
//            item.folderId ?? item.shareId
//        case let .folder(folder):
//            folder.parentId
//        }
//    }
// }

public typealias ContainerId = String

public struct ShareContent: Identifiable, Hashable, Sendable {
    public let share: Share

    private let itemsByContainer: [ContainerId: [ItemUiModel]]
    private let foldersByContainer: [ContainerId: [FolderUiModel]]
    private let foldersById: [String: FolderUiModel]

    public let itemCount: Int
    public let aliasCount: Int
    public let totpCount: Int

    public var id: String {
        share.id
    }

    public init(share: Share, elements: [ShareContentElement]) {
        self.share = share

        var itemCount = 0
        var aliasCount = 0
        var totpCount = 0
        var itemsByContainer = [ContainerId: [ItemUiModel]]()
        var foldersByContainer = [ContainerId: [FolderUiModel]]()
        var foldersById = [String: FolderUiModel]()

        for element in elements {
            switch element {
            case let .item(item):
                itemCount += 1
                if item.isAlias { aliasCount += 1 }
                if item.hasTotpUri { totpCount += 1 }
                itemsByContainer[element.containerId, default: []].append(item)

            case let .folder(folder):
                foldersByContainer[element.containerId, default: []].append(folder)
                foldersById[folder.folderId] = folder
            }
        }

        self.itemCount = itemCount
        self.aliasCount = aliasCount
        self.totpCount = totpCount
        self.itemsByContainer = itemsByContainer
        self.foldersByContainer = foldersByContainer
        self.foldersById = foldersById
    }
}

public extension ShareContent {
    var allElements: [ShareContentElement] {
        var result = [ShareContentElement]()
        result.reserveCapacity(itemCount + foldersById.count)

        for items in itemsByContainer.values {
            for item in items {
                result.append(.item(item))
            }
        }
        for folders in foldersByContainer.values {
            for folder in folders {
                result.append(.folder(folder))
            }
        }

        return result
    }

    var allItems: [ItemUiModel] {
        var result = [ItemUiModel]()
        result.reserveCapacity(itemCount)

        for items in itemsByContainer.values {
            result.append(contentsOf: items)
        }

        return result
    }

    var allFolders: [FolderUiModel] {
        Array(foldersById.values)
    }

    func element(in containerId: String, for id: String) -> ShareContentElement? {
        if let item = itemsByContainer[containerId]?.first(where: { $0.id == id }) {
            return .item(item)
        }
        if let folder = foldersByContainer[containerId]?.first(where: { $0.folderId == id }) {
            return .folder(folder)
        }
        return nil
    }

    func elements(for containerId: String) -> [ShareContentElement]? {
        let items = itemsByContainer[containerId]
        let folders = foldersByContainer[containerId]

        guard items != nil || folders != nil else { return nil }

        var result = [ShareContentElement]()
        if let items {
            result.append(contentsOf: items.map { .item($0) })
        }
        if let folders {
            result.append(contentsOf: folders.map { .folder($0) })
        }
        return result
    }

    func folder(for id: String) -> FolderUiModel? {
        foldersById[id]
    }

    func flattenedItems(from containerId: String) -> [ItemUiModel] {
        var items = itemsByContainer[containerId] ?? []

        if let folders = foldersByContainer[containerId] {
            for folder in folders {
                items.append(contentsOf: flattenedItems(from: folder.folderId))
            }
        }

        return items
    }

    func flattenedFolders(from containerId: String) -> [FolderUiModel] {
        var folders = foldersByContainer[containerId] ?? []

        let directFolders = folders
        for folder in directFolders {
            folders.append(contentsOf: flattenedFolders(from: folder.folderId))
        }

        return folders
    }

    func items(in containerId: String) -> [ItemUiModel]? {
        itemsByContainer[containerId]
    }

    func folders(in containerId: String) -> [FolderUiModel]? {
        foldersByContainer[containerId]
    }

    var rootElements: [ShareContentElement] {
        elements(for: share.id) ?? []
    }

    func getPath(forElementWithContainer id: String) -> [FolderUiModel] {
        var path = [FolderUiModel]()
        var containerId: String? = id

        while let currentId = containerId, let folder = foldersById[currentId] {
            path.append(folder)
            containerId = folder.isRootFolder ? nil : folder.parentId
        }

        path.reverse()
        return path
    }
}

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
        case let .item(item): item.folderId ?? item.shareId
        case let .folder(folder): folder.parentId
        }
    }
}
