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

public typealias ContainerId = String

public struct ShareContent: Identifiable, Hashable, Sendable {
    public let share: Share

    private let content: [ContainerId: [ShareContentElement]]

    private let itemsByContainer: [ContainerId: [ShareContentElement]]
    private let foldersByContainer: [ContainerId: [ShareContentElement]]
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
        var content = [ContainerId: [ShareContentElement]]()
        // TODO: peut etre mettre element de type itemUiModel ou folder ui model
        var itemsByContainer = [ContainerId: [ShareContentElement]]()
        var foldersByContainer = [ContainerId: [ShareContentElement]]()
        for element in elements {
            content[element.containerId, default: []].append(element)
            if case let .item(item) = element {
                itemCount += 1
                aliasCount += item.isAlias ? 1 : 0
                totpCount += item.hasTotpUri ? 1 : 0
            }

            switch element {
            case .item:
                itemsByContainer[element.containerId, default: []].append(element)

            case .folder:
                foldersByContainer[element.containerId, default: []].append(element)
            }
        }
        self.itemCount = itemCount
        self.aliasCount = aliasCount
        self.totpCount = totpCount
        self.content = content
        self.itemsByContainer = itemsByContainer
        self.foldersByContainer = foldersByContainer
//        self.allElements = elements.reduce(<#T##initialResult: Result##Result#>, <#T##nextPartialResult: (Result,
//        ShareContentElement) throws -> Result##(Result, ShareContentElement) throws -> Result##(_ partialResult:
//        Result, ShareContentElement) throws -> Result#>)
//        self.content = Dictionary(grouping: elements, by: \.containerId)
//        self.lookupTable = ShareContentIndex(shareID: share.id, elements: elements)
    }
}

public extension ShareContent {
    var allElements: [ShareContentElement] {
        var result: [ShareContentElement] = []
        result.reserveCapacity(content.values.reduce(0) { $0 + $1.count })

        for bucket in content.values {
            result.append(contentsOf: bucket)
        }

        return result
    }

    var allItems: [ItemUiModel] {
        var result: [ItemUiModel] = []
        result.reserveCapacity(itemsByContainer.values.reduce(0) { $0 + $1.count })

        for bucket in content.values {
            for element in bucket {
                if case let .item(item) = element {
                    result.append(item)
                }
            }
        }

        return result
    }

//    func contains(_ id: String) -> Bool {
//        lookupTable.contains(id)
//    }

    func element(in containerId: String, for id: String) -> ShareContentElement? {
        content[containerId]?.first { $0.id == id }
//        lookupTable.element(for: id)
    }

    func elements(for containerId: String) -> [ShareContentElement]? {
        content[containerId]
//        lookupTable.elements(for: containerId)
    }

    func flatenedItems(from containerId: String) -> [ItemUiModel] {
        var items = itemsByContainer[containerId]?.compactMap(\.itemValue) ?? []
        if let folders = foldersByContainer[containerId], !folders.isEmpty {
            for folder in folders {
                let subfolderItems = itemsByContainer[folder.id]?.compactMap(\.itemValue) ?? []
                items.append(contentsOf: subfolderItems)
            }
        }
        return items
    }

    func items(in containerId: String) -> [ItemUiModel]? {
        itemsByContainer[containerId]?.compactMap(\.itemValue)
//        lookupTable.items(in: containerId)
    }

    func folders(in containerId: String) -> [FolderUiModel]? {
        foldersByContainer[containerId]?.compactMap(\.folderValue)
//        lookupTable.subfolders(of: containerId)
    }

    var rootElements: [ShareContentElement] {
        content[share.id] ?? []
    }
}

public enum ShareContentElement: Sendable, Equatable, Hashable, Identifiable {
    case item(ItemUiModel)
    case folder(FolderUiModel)

    public var id: String {
        switch self {
        case let .item(content):
            content.id
        case let .folder(folder):
            folder.folderId
        }
    }

    public var isFolder: Bool {
        switch self {
        case .folder:
            true
        default:
            false
        }
    }

    public var shareId: String {
        switch self {
        case let .item(item):
            item.shareId
        case let .folder(folder):
            folder.shareId
        }
    }

//    public var content: [ShareContentElement] {
//        switch self {
//        case .item:
//            return []
//        case let.folder(folder):
//            return folder.content
//        }
//    }

    public var itemValue: ItemUiModel? {
        switch self {
        case let .item(item):
            item
        default:
            nil
        }
    }

    public var folderValue: FolderUiModel? {
        switch self {
        case let .folder(folder):
            folder
        default:
            nil
        }
    }

    public var shared: Bool {
        switch self {
        case let .item(item):
            item.shared
        case .folder:
            false
        }
    }

    public var containerId: String {
        switch self {
        case let .item(item):
            item.folderId ?? item.shareId
        case let .folder(folder):
            folder.parentId
        }
    }
}

extension ShareContentElement {
//    public var id: ShareContentID {
//        switch self {
//        case let .item(item):
//            return .item(item.id)
//        case let .folder(folder):
//            return .folder(folder.folderId)
//        }
//    }

//    public var children: [ShareContentElement] {
//        switch self {
//        case .item:
//            return []
//        case let.folder(folder):
//            return folder.content
//        }
//    }
//
//
//
//    public var fullItemCount: Int {
//        switch self {
//        case .item:
//            return 1
//        case let .folder(folder):
//            return folder.content.reduce(0) { $0 + $1.fullItemCount }
//        }
//    }
//
//    public var items: [ItemUiModel] {
//        switch self {
//        case let .item(item):
//            return [item]
//        case let .folder(folder):
//            return folder.content.flatMap(\.items)
//        }
//    }
}

// public extension [ShareContentElement] {
//    var numberOfAllItems: Int {
//        reduce(0) { $0 + $1.fullItemCount }
//    }
//
//    var numberOfItems: Int {
//        reduce(0) { $0 + ($1.isFolder ? 0 : 1) }
//    }
//
//    var allItems: [ItemUiModel] {
//        reduce([]) { $0 + $1.items }
//    }
// }
//
//

// public enum ShareContentID: Hashable, Sendable, Equatable {
//    case item(String)
//    case folder(String)
//
//    var contentId: String {
//        switch self {
//        case .item(let id): return id
//        case .folder(let id): return id
//        }
//    }
// }

// public struct ShareContentIndex: Sendable, Equatable, Hashable {
//
//    public struct Entry: Sendable, Equatable, Hashable {
//        public let element: ShareContentElement
//        public let path: [ShareContentID]
//    }
//
//    private let entries: [ShareContentID: Entry]
//
//    public init(elements: [ShareContentElement]) {
//        self.entries = Self.buildIndex(from: elements)
//    }
//
//    // MARK: - Public API
//
//    public func contains(_ id: ShareContentID) -> Bool {
//        entries[id] != nil
//    }
//
//    public func element(for id: ShareContentID) -> ShareContentElement? {
//        entries[id]?.element
//    }
//
//    public func path(to id: ShareContentID) -> [ShareContentID]? {
//        entries[id]?.path
//    }
// }
//
// private extension ShareContentIndex {
//
//    static func buildIndex(from roots: [ShareContentElement]) -> [ShareContentID: Entry] {
//        var result: [ShareContentID: Entry] = [:]
//
//        roots.forEach {
//            walk(
//                element: $0,
//                path: [],
//                into: &result
//            )
//        }
//
//        return result
//    }
//
//     static func walk(element: ShareContentElement,
//        path: [ShareContentID],
//        into index: inout [ShareContentID: Entry]) {
//        let id = element.id
//        let currentPath = path + [id]
//
//        index[id] = Entry(
//            element: element,
//            path: currentPath
//        )
//
//        element.children.forEach {
//            walk(
//                element: $0,
//                path: currentPath,
//                into: &index
//            )
//        }
//    }
// }

// **********************************************************
//
//
//
// public struct ShareContentIndex: Sendable, Equatable, Hashable {
//
//    public struct Entry: Sendable, Equatable, Hashable {
//        public let element: ShareContentElement
//        public let path: [String]
//        public let containerId: String
//    }
//
//    private let entries: [String: Entry]
//
//    private let itemCountByContainer: [String: Int]
//    private let subfoldersByContainer: [String: [FolderUiModel]]
//    private let itemsByContainer: [String: [ItemUiModel]]
//    private let elementsByContainer: [String: [ShareContentElement]]
//    let allItems: [ItemUiModel]
//
//    public init(shareID: String, elements: [ShareContentElement]) {
//        var entries: [String: Entry] = [:]
//        var itemCounts: [String: Int] = [:]
//        var subfolders: [String: [FolderUiModel]] = [:]
//        var itemsByContainer: [String: [ItemUiModel]] = [:]
//        var elementsByContainer = [String: [ShareContentElement]]()
//        var allItems: [ItemUiModel] = []
//
//        let rootId = shareID
//        itemCounts[rootId] = 0
//        subfolders[rootId] = []
//        itemsByContainer[rootId] = []
//
//        elements.forEach {
//            Self.walk(
//                element: $0,
//                path: [],
//                containerId: rootId,
//                entries: &entries,
//                itemCounts: &itemCounts,
//                subfolders: &subfolders,
//                itemsByContainer: &itemsByContainer,
//                elementsByContainer: &elementsByContainer,
//                allItems: &allItems
//            )
//        }
//
//        self.entries = entries
//        self.itemCountByContainer = itemCounts
//        self.subfoldersByContainer = subfolders
//        self.itemsByContainer = itemsByContainer
//        self.allItems = allItems
//        self.elementsByContainer = elementsByContainer
//    }
//
//    private static func walk(
//        element: ShareContentElement,
//        path: [String],
//        containerId: String,
//        entries: inout [String: Entry],
//        itemCounts: inout [String: Int],
//        subfolders: inout [String: [FolderUiModel]],
//        itemsByContainer: inout [String: [ItemUiModel]],
//        elementsByContainer: inout [String: [ShareContentElement]],
//        allItems: inout [ItemUiModel]
//    ) {
//        let id = element.id
//        let currentPath = path + [id]
//
//        entries[id] = Entry(
//            element: element,
//            path: currentPath,
//            containerId: containerId
//        )
//
//        switch element {
//        case let .item(item):
//            itemCounts[containerId, default: 0] += 1
//            itemsByContainer[containerId, default: []].append(item)
//            elementsByContainer[containerId, default: []].append(element)
//            allItems.append(item)
//
//        case let .folder(folder):
//            let folderId = folder.folderId
//
//            subfolders[containerId, default: []].append(folder)
//            elementsByContainer[containerId, default: []].append(element)
//            itemCounts[folderId] = 0
//            subfolders[folderId] = []
//            itemsByContainer[folderId] = []
//
//            folder.content.forEach {
//                walk(
//                    element: $0,
//                    path: currentPath,
//                    containerId: folderId,
//                    entries: &entries,
//                    itemCounts: &itemCounts,
//                    subfolders: &subfolders,
//                    itemsByContainer: &itemsByContainer,
//                    elementsByContainer: &elementsByContainer,
//                    allItems: &allItems
//                )
//            }
//        }
//    }
// }
//
// public extension ShareContentIndex {
//
//    /// Direct items in a container
//    func items(in container: String) -> [ItemUiModel] {
//        itemsByContainer[container] ?? []
//    }
//
//    /// Total number of items in the share
//      var totalItemCount: Int {
//          allItems.count
//      }
//
//    /// Number of direct items in a container
//    func itemCount(in container: String) -> Int {
//        itemCountByContainer[container] ?? 0
//    }
//
//    /// Direct subfolders of a container
//    func subfolders(of container: String) -> [FolderUiModel] {
//        subfoldersByContainer[container] ?? []
//    }
//
//    // MARK: - Public API
//
//    func contains(_ id: String) -> Bool {
//        entries[id] != nil
//    }
//
//    func element(for id: String) -> ShareContentElement? {
//        entries[id]?.element
//    }
//
//    func elements(for containerId: String) -> [ShareContentElement]? {
//        elementsByContainer[containerId]
//    }
//
//    func path(to id: String) -> [String]? {
//        entries[id]?.path
//    }
// }
