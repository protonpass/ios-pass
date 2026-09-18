//
// SharesData.swift
// Proton Pass - Created on 28/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

public struct SharesData: Hashable, Sendable {
    public let shares: [String: ShareContent]
    public let trashedItems: [ItemUiModel]
    public let itemsSharedByMe: [ItemUiModel]
    public let itemsSharedWithMe: [ItemUiModel]

    public init(shares: [ShareContent], trashedItems: [ItemUiModel]) {
        var sharesDictionary: [String: ShareContent] = [:]
        sharesDictionary.reserveCapacity(shares.count)

        var sharedByMeContents: [ShareContent] = []
        var sharedWithMeContents: [ShareContent] = []
        var sharedByMeShareIds: Set<String> = []
        var sharedWithMeShareIds: Set<String> = []

        // Single pass: build dictionary and categorize simultaneously
        for shareContent in shares {
            let share = shareContent.share
            sharesDictionary[share.shareId] = shareContent

            if share.shareRole == .manager {
                sharedByMeShareIds.insert(share.shareId)
                sharedByMeContents.append(shareContent)
            }
            if !share.isVaultRepresentation, !share.owner {
                sharedWithMeShareIds.insert(share.shareId)
                sharedWithMeContents.append(shareContent)
            }
        }

        self.shares = sharesDictionary
        self.trashedItems = trashedItems
        let sharedTrashedItems = trashedItems.filter(\.shared)
        itemsSharedByMe = sharedByMeContents.flatMap(\.allItems).filter(\.shared)
            + sharedTrashedItems.filter { sharedByMeShareIds.contains($0.shareId) }

        itemsSharedWithMe = sharedWithMeContents.flatMap(\.allItems)
            + sharedTrashedItems.filter { sharedWithMeShareIds.contains($0.shareId) }
    }

    public var filteredOrderedVaults: [ShareContent] {
        shares.values
            .filter(\.share.isVaultRepresentation)
            .sorted { lhs, rhs in
                guard let lhsName = lhs.share.vaultName,
                      let rhsName = rhs.share.vaultName else { return false }
                return lhsName == rhsName
                    ? lhs.share.createTime < rhs.share.createTime
                    : lhsName < rhsName
            }
    }

    public var isEmpty: Bool {
        shares.isEmpty &&
            trashedItems.isEmpty &&
            itemsSharedByMe.isEmpty &&
            itemsSharedWithMe.isEmpty
    }

    public var hiddenSharesIds: [String] {
        shares.values.compactMap { shareContent in
            guard shareContent.share.hidden else {
                return nil
            }
            return shareContent.id
        }
    }

    public var visibleShareContents: [ShareContent] {
        shares.values.filter { !$0.share.hidden }
    }

    public var vaultCount: Int {
        shares.values.count(where: \.share.isVaultRepresentation)
    }

    /// Items directly contained by `selection`, without recursing into sub folders.
    /// Both the displayed item list and the item type filter counts must derive from here,
    /// or the counts stop describing the list.
    public func items(for selection: ShareSelection) -> [ItemUiModel] {
        switch selection {
        case .all:
            visibleShareContents.flatMap(\.allItems)

        case let .precise(selection):
            shares[selection.share.id]?
                .items(in: selection.folder?.folderId ?? selection.share.shareId) ?? []

        case .sharedByMe:
            itemsSharedByMe

        case .sharedWithMe:
            itemsSharedWithMe

        case .trash:
            trashedItems(excluding: Set(hiddenSharesIds))
        }
    }

    private func trashedItems(excluding hiddenShareIds: Set<String>) -> [ItemUiModel] {
        trashedItems.filter { !hiddenShareIds.contains($0.shareId) }
    }
}
