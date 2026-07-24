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

private typealias ContainerId = String

public struct ShareContent: Identifiable, Hashable, Sendable {
    public let share: Share
    public let itemCount: Int
    public let aliasCount: Int
    public let totpCount: Int

    private let itemsByContainer: [ContainerId: [ItemUiModel]]
    private let foldersByContainer: [ContainerId: [FolderUiModel]]
    private let foldersById: [String: FolderUiModel]

    public var id: String {
        share.id
    }

    public var isReadOnly: Bool {
        share.shareRole == .read
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
                if item.isAlias {
                    aliasCount += 1
                }
                if item.hasTotpUri {
                    totpCount += 1
                }
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

    var rootElements: [ShareContentElement] {
        elements(for: share.id) ?? []
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

    func getPathOfElement(containerId id: String) -> [FolderUiModel] {
        var path = [FolderUiModel]()
        var containerId: String? = id

        while let currentId = containerId, let folder = foldersById[currentId] {
            path.append(folder)
            containerId = folder.isRootFolder ? nil : folder.parentId
        }

        path.reverse()
        return path
    }

    func containsSubfolders(containerId: String) -> Bool {
        guard let subfolders = foldersByContainer[containerId] else {
            return false
        }
        return !subfolders.isEmpty
    }
}

// MARK: - Folder limits

public extension ShareContent {
    var totalFolderCount: Int {
        foldersById.count
    }

    func isVaultFolderLimitReached(limits: FolderLimits) -> Bool {
        totalFolderCount >= limits.maxFoldersPerVault
    }

    /// Layer of a container relative to the vault (vault = 0, root folders = 1, …).
    func depth(of containerId: String) -> Int {
        containerId == share.id ? 0 : getPathOfElement(containerId: containerId).count
    }

    /// `true` when a new folder can be added directly under `parentId` (vault id or folder id).
    func canAddFolder(in parentId: String, limits: FolderLimits) -> Bool {
        guard !isReadOnly else { return false }
        guard !isVaultFolderLimitReached(limits: limits) else { return false }
        guard depth(of: parentId) < limits.maxFolderDepth else { return false }
        return (foldersByContainer[parentId]?.count ?? 0) < limits.maxFoldersPerLayer
    }

    /// Maximum depth (in layers) of the subtree rooted at `folderId`, relative to `folderId`.
    /// A leaf folder returns 0; a folder with direct children returns 1; etc.
    func subtreeDepth(from folderId: String) -> Int {
        guard let children = foldersByContainer[folderId], !children.isEmpty else { return 0 }
        var maxBelow = 0
        for child in children {
            let below = subtreeDepth(from: child.folderId)
            if below > maxBelow {
                maxBelow = below
            }
        }
        return maxBelow + 1
    }

    /// Validates that `folderId` can be moved under `newParentId` (use `nil` to move to the vault root).
    /// Throws `PassError.folder(...)` describing the first broken rule.
    func validateMove(folderId: String, to newParentId: String?, limits: FolderLimits) throws {
        let destinationId = newParentId ?? share.id
        let destinationDepth = depth(of: destinationId)
        let movedSubtreeDepth = subtreeDepth(from: folderId)
        let destinationName = foldersById[destinationId]?.content.name ?? share.vaultName ?? ""

        if destinationDepth + 1 + movedSubtreeDepth > limits.maxFolderDepth {
            throw PassError.folder(.depthExceeded(container: destinationName, limit: limits.maxFolderDepth))
        }

        let currentParentId = foldersById[folderId]?.parentId
        let isSameParent = currentParentId == destinationId
        let destinationChildren = foldersByContainer[destinationId]?.count ?? 0

        if !isSameParent, destinationChildren >= limits.maxFoldersPerLayer {
            throw PassError.folder(.layerFull(container: destinationName, limit: limits.maxFoldersPerLayer))
        }
    }
}
