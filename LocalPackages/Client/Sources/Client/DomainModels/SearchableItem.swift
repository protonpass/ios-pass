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
import Entities

/// Items that live in memory for search purpose
public struct SearchableItem: ItemTypeIdentifiable, Equatable {
    public let shareId: String
    public let itemId: String
    public let vault: Vault? // Optional because we only show vault when there're more than 1 vault
    public let type: ItemContentType
    public let aliasEmail: String?
    public let name: String
    public let note: String
    public let url: String?
    public let requiredExtras: [String] // E.g: Username for login items
    public let optionalExtras: [String] // E.g: URLs for login items
    public let lastUseTime: Int64
    public let modifyTime: Int64
    public let pinned: Bool

    public init(from item: SymmetricallyEncryptedItem,
                symmetricKey: SymmetricKey,
                allVaults: [Vault]) throws {
        itemId = item.item.itemID
        shareId = item.shareId

        if allVaults.count > 1 {
            vault = allVaults.first { $0.shareId == item.shareId }
        } else {
            vault = nil
        }

        let itemContent = try item.getItemContent(symmetricKey: symmetricKey)
        type = itemContent.contentData.type
        aliasEmail = item.item.aliasEmail
        name = itemContent.name
        note = itemContent.note

        var optionalExtras: [String] = []

        switch itemContent.contentData {
        case let .login(data):
            url = data.urls.first
            requiredExtras = [data.username]
            optionalExtras = data.urls
        default:
            url = nil
            requiredExtras = []
            optionalExtras = []
        }

        for customField in itemContent.customFields where customField.type == .text {
            optionalExtras.append("\(customField.title): \(customField.content)")
        }

        lastUseTime = itemContent.item.lastUseTime ?? 0
        modifyTime = item.item.modifyTime
        pinned = item.item.pinned
        self.optionalExtras = optionalExtras
    }
}

extension SearchableItem {
    func result(for term: String) -> ItemSearchResult? {
        let title: SearchResultEither = if let result = SearchUtils.fuzzySearch(query: term, in: name) {
            .matched(result)
        } else {
            .notMatched(name)
        }

        var detail = [SearchResultEither]()
        if let result = SearchUtils.fuzzySearch(query: term, in: note) {
            detail.append(.matched(result))
        } else {
            detail.append(.notMatched(note))
        }

        for extra in requiredExtras {
            if let result = SearchUtils.fuzzySearch(query: term, in: extra) {
                detail.append(.matched(result))
            } else {
                detail.append(.notMatched(extra))
            }
        }

        for extra in optionalExtras {
            if let result = SearchUtils.fuzzySearch(query: term, in: extra) {
                detail.append(.matched(result))
            }
        }

        let detailNotMatched = detail.allSatisfy { either in
            if case .matched = either {
                false
            } else {
                true
            }
        }

        if case .notMatched = title, detailNotMatched {
            return nil
        }

        return .init(shareId: shareId,
                     itemId: itemId,
                     type: type,
                     aliasEmail: aliasEmail,
                     title: title,
                     detail: detail,
                     url: url,
                     vault: vault,
                     lastUseTime: lastUseTime,
                     modifyTime: modifyTime,
                     pinned: pinned)
    }

    var toItemSearchResult: ItemSearchResult {
        ItemSearchResult(shareId: shareId,
                         itemId: itemId,
                         type: type,
                         aliasEmail: aliasEmail,
                         title: .notMatched(name),
                         detail: [.notMatched(note)],
                         url: url,
                         vault: vault,
                         lastUseTime: lastUseTime,
                         modifyTime: modifyTime,
                         pinned: pinned)
    }

    public var toSearchEntryUiModel: SearchEntryUiModel {
        SearchEntryUiModel(itemId: itemId,
                           shareId: shareId,
                           type: type,
                           title: name,
                           url: url,
                           description: note)
    }
}

public extension [SearchableItem] {
    func result(for term: String) -> [ItemSearchResult] {
        compactMap { $0.result(for: term) }
    }

    var toItemSearchResults: [ItemSearchResult] {
        self.map(\.toItemSearchResult)
    }
}
