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

import CryptoKit

public struct SharesData: Hashable, Sendable {
    public let shares: [String: ShareContent]
    public let trashedItems: [ItemUiModel]
    public let itemsSharedByMe: [ItemUiModel]
    public let itemsSharedWithMe: [ItemUiModel]

    public init(shares: [ShareContent], trashedItems: [ItemUiModel]) {
        self.shares = shares.reduce(into: [String: ShareContent]()) { result, shareContent in
            result[shareContent.share.id] = shareContent
        }
        self.trashedItems = trashedItems

        var sharedByMeShareIds: Set<String> = []
        var sharedWithMeShareIds: Set<String> = []

        for share in shares {
            if share.share.shareRole == .manager {
                sharedByMeShareIds.insert(share.share.shareId)
            }
            if !share.share.isVaultRepresentation, !share.share.owner {
                sharedWithMeShareIds.insert(share.share.shareId)
            }
        }

        let sharedTrashedItems = self.trashedItems.filter(\.shared)
        let trashedSharedByMeItems = sharedTrashedItems.filter { sharedByMeShareIds.contains($0.shareId) }
        let trashedSharedWithMeItems = sharedTrashedItems.filter { sharedWithMeShareIds.contains($0.shareId) }

        itemsSharedByMe =
            self.shares.values
                .filter { sharedByMeShareIds.contains($0.share.shareId) }
                .flatMap(\.allItems)
                .filter(\.shared) + trashedSharedByMeItems

        itemsSharedWithMe = self.shares.values
            .filter { sharedWithMeShareIds.contains($0.share.shareId) }
            .flatMap(\.allItems)
            + trashedSharedWithMeItems
    }

    public var filteredOrderedVaults: [ShareContent] {
        shares.values
            .filter { $0.share.vaultName != nil }
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
        shares.values.compactMap { shareContent in
            guard !shareContent.share.hidden else {
                return nil
            }
            return shareContent
        }
    }
}
