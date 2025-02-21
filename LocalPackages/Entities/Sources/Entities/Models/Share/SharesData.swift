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
    public let shares: [ShareContent]
    public let trashedItems: [ItemUiModel]
    public let itemsSharedByMe: [ItemUiModel]
    public let itemsSharedWithMe: [ItemUiModel]

    public init(shares: [ShareContent], trashedItems: [ItemUiModel]) {
        self.shares = shares
        self.trashedItems = trashedItems

        let sharedByMeShareIds = shares
            .filter { $0.share.shareRole == .admin }
            .map(\.share.shareId)
        let trashedSharedByMeItems = trashedItems.filter { sharedByMeShareIds.contains($0.shareId) }

        itemsSharedByMe =
            shares
                .filter { sharedByMeShareIds.contains($0.share.shareId) }
                .flatMap(\.items)
                .filter(\.isShared) +
                trashedSharedByMeItems

        let sharedWithMeShareIds = shares
            .filter { !$0.share.isVaultRepresentation && !$0.share.owner }
            .map(\.share.shareId)
        let trashedSharedWithMeItems = trashedItems.filter { sharedWithMeShareIds.contains($0.shareId) }

        itemsSharedWithMe = shares
            .filter { sharedWithMeShareIds.contains($0.share.shareId) }
            .flatMap(\.items) +
            trashedSharedWithMeItems
    }

    public var filteredOrderedVaults: [Share] {
        shares
            .compactMap { shareContent -> Share? in
                guard shareContent.share.vaultName != nil else { return nil }
                return shareContent.share
            }
            .sorted { lhs, rhs in
                guard let lhsName = lhs.vaultName,
                      let rhsName = rhs.vaultName else { return false }
                return lhsName < rhsName
            }
    }

    public var isEmpty: Bool {
        shares.isEmpty &&
            trashedItems.isEmpty &&
            itemsSharedByMe.isEmpty &&
            itemsSharedWithMe.isEmpty
    }
}
