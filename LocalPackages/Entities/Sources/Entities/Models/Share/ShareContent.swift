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


public struct ShareContent: Identifiable, Hashable, Sendable {
    public let share: Share
    /// `Active` items only
    public let elements: [ShareContentElement]
    
    // Lookup table for O(1) access to any element in the tree
    public let lookupTable: ShareContentIndex //[String: (element: ShareContentElement, path: [String])]

    public var id: String {
        share.id
    }

    public var itemCount: Int {
        elements.numberOfItems
    }
    
    public var completeItemCount: Int {
        elements.numberOfAllItems
    }

    public init(share: Share, elements: [ShareContentElement]) {
        self.share = share
        self.elements = elements
        self.lookupTable = ShareContentIndex(elements: elements)
    }
}

public enum ShareContentElement: Sendable, Equatable, Hashable {
    case item(ItemUiModel)
    case folder(FolderUiModel)
}


extension ShareContentElement {
    public var id: ShareContentID { nodeID }

    public var nodeID: ShareContentID {
        switch self {
        case let .item(item):
            return .item(item.id)
        case let .folder(folder):
            return .folder(folder.folderId)
        }
    }

    public var children: [ShareContentElement] {
        switch self {
        case .item:
            return []
        case .folder(let folder):
            return folder.content
        }
    }
    
    public var isFolder: Bool {
        switch self {
        case .folder:
            return true
        case .item:
            return false
        }
    }
    
    public var fullItemCount: Int {
        switch self {
        case .item:
            return 1
        case let .folder(folder):
            return folder.content.reduce(0) { $0 + $1.fullItemCount }
        }
    }
    
    public var items: [ItemUiModel] {
        switch self {
        case let .item(item):
            return [item]
        case let .folder(folder):
            return folder.content.flatMap(\.items)
        }
    }
    
    public var sharedId: String {
        switch self {
        case let .item(item):
            return item.shareId
        case let .folder(folder):
            return folder.shareId
        }
    }
}

public extension [ShareContentElement] {
    var numberOfAllItems: Int {
        reduce(0) { $0 + $1.fullItemCount }
    }
    
    var numberOfItems: Int {
        reduce(0) { $0 + ($1.isFolder ? 0 : 1) }
    }
    
    var allItems: [ItemUiModel] {
        reduce([]) { $0 + $1.items }
    }
}


public struct FolderUiModel: PrecomputedHashable, Equatable, Sendable, Identifiable {
    // Existing properties
    public var id: String { folderId + shareId }
    public let folderId: String
    public let shareId: String
    public let content: [ShareContentElement]
    
    public let precomputedHash: Int
    
    public init(folderId: String, shareId: String, content: [ShareContentElement]) {
        self.folderId = folderId
        self.shareId = shareId
        self.content = content
        var hasher = Hasher()
        hasher.combine(folderId)
        hasher.combine(shareId)
        hasher.combine(content)
        precomputedHash = hasher.finalize()
    }
}

public enum ShareContentID: Hashable, Sendable, Equatable {
    case item(String)
    case folder(String)
}

public struct ShareContentIndex: Sendable, Equatable, Hashable {

    public struct Entry: Sendable, Equatable, Hashable {
        public let element: ShareContentElement
        public let path: [ShareContentID]
    }

    private let entries: [ShareContentID: Entry]

    public init(elements: [ShareContentElement]) {
        self.entries = Self.buildIndex(from: elements)
    }

    // MARK: - Public API

    public func contains(_ id: ShareContentID) -> Bool {
        entries[id] != nil
    }

    public func element(for id: ShareContentID) -> ShareContentElement? {
        entries[id]?.element
    }

    public func path(to id: ShareContentID) -> [ShareContentID]? {
        entries[id]?.path
    }
}

private extension ShareContentIndex {

    static func buildIndex(from roots: [ShareContentElement]) -> [ShareContentID: Entry] {
        var result: [ShareContentID: Entry] = [:]

        roots.forEach {
            walk(
                element: $0,
                path: [],
                into: &result
            )
        }

        return result
    }

     static func walk(element: ShareContentElement,
        path: [ShareContentID],
        into index: inout [ShareContentID: Entry]) {
        let id = element.nodeID
        let currentPath = path + [id]

        index[id] = Entry(
            element: element,
            path: currentPath
        )

        element.children.forEach {
            walk(
                element: $0,
                path: currentPath,
                into: &index
            )
        }
    }
}
