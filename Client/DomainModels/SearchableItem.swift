//
// SearchableItem.swift
// Proton Pass - Created on 21/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import CryptoKit

/// Items that live in memory for search purpose
public struct SearchableItem {
    public let shareId: String
    public let itemId: String
    public let encryptedItemContent: ItemContent
    public let vaultName: String

    public init(symmetricallyEncryptedItem: SymmetricallyEncryptedItem) throws {
        self.shareId = symmetricallyEncryptedItem.shareId
        self.itemId = symmetricallyEncryptedItem.item.itemID
        self.encryptedItemContent = try symmetricallyEncryptedItem.getEncryptedItemContent()
        self.vaultName = "Vault name"
    }
}

extension SearchableItem {
    func result(for term: String, symmetricKey: SymmetricKey) throws -> ItemSearchResult? {
        let decryptedName = try symmetricKey.decrypt(encryptedItemContent.name)
        let title: SearchResultEither
        if let result = SearchUtils.search(query: term, in: decryptedName) {
            title = .matched(result)
        } else {
            title = .notMatched(decryptedName)
        }

        var detail = [SearchResultEither]()
        let decryptedNote = try symmetricKey.decrypt(encryptedItemContent.note)
        if let result = SearchUtils.search(query: term, in: decryptedNote) {
            detail.append(.matched(result))
        } else {
            detail.append(.notMatched(decryptedNote))
        }

        if case let .login(username, _, urls) = encryptedItemContent.contentData {
            let decryptedUsername = try symmetricKey.decrypt(username)
            if let result = SearchUtils.search(query: term, in: decryptedUsername) {
                detail.append(.matched(result))
            } else {
                detail.append(.notMatched(decryptedUsername))
            }

            let decryptedUrls = try urls.map { try symmetricKey.decrypt($0) }
            for decryptedUrl in decryptedUrls {
                if let result = SearchUtils.search(query: term, in: decryptedUrl) {
                    detail.append(.matched(result))
                }
            }
        }

        let detailNotMatched = detail.contains { either in
            if case .matched = either {
                return false
            } else {
                return true
            }
        }

        if case .notMatched = title, detailNotMatched {
            return nil
        }

        return .init(shareId: shareId,
                     itemId: itemId,
                     type: encryptedItemContent.contentData.type,
                     title: title,
                     detail: detail,
                     vaultName: vaultName)
    }
}

public extension Array where Element == SearchableItem {
    func result(for term: String, symmetricKey: SymmetricKey) throws -> [ItemSearchResult] {
        try compactMap { try $0.result(for: term, symmetricKey: symmetricKey) }
    }
}
