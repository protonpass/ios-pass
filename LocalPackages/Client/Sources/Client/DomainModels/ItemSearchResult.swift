//
// ItemSearchResult.swift
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
import Entities
import UIKit

public protocol HighlightableText: Sendable, Hashable {
    var fullText: String { get }
    var highlightText: String? { get }
    var isLeadingText: Bool { get }
    var isTrailingText: Bool { get }
}

public enum SearchResultEither: HighlightableText, Hashable {
    case notMatched(String)
    case matched(SearchResult)

    public var fullText: String {
        switch self {
        case let .notMatched(text):
            text
        case let .matched(searchResult):
            searchResult.matchedPhrase
        }
    }

    public var highlightText: String? {
        switch self {
        case .notMatched:
            nil
        case let .matched(searchResult):
            searchResult.matchedWord
        }
    }

    public var isLeadingText: Bool {
        switch self {
        case .notMatched:
            true
        case let .matched(searchResult):
            searchResult.isLeadingPhrase
        }
    }

    public var isTrailingText: Bool {
        switch self {
        case .notMatched:
            true
        case let .matched(searchResult):
            searchResult.isTrailingPhrase
        }
    }
}

public struct ItemSearchResult: Sendable, ItemTypeIdentifiable, Identifiable, Pinnable {
    public var id: String {
        "\(itemId + shareId)"
    }

    public let shareId: String
    public let itemId: String
    public let type: ItemContentType
    public let aliasEmail: String?
    public let aliasEnabled: Bool
    public let highlightableTitle: any HighlightableText
    public let highlightableDetail: [any HighlightableText]
    // `totpUri` to conform to ItemTypeIdentifiable protocol
    // but always nil because not applicable to search results
    public var totpUri: String?
    public let url: String?
    public let vault: Share?
    public let lastUseTime: Int64
    public let modifyTime: Int64
    public let pinned: Bool
    public let owner: Bool
    public let shared: Bool

    public let precomputedHash: Int

    public init(shareId: String,
                itemId: String,
                type: ItemContentType,
                aliasEmail: String?,
                aliasEnabled: Bool,
                title: SearchResultEither,
                detail: [SearchResultEither],
                url: String?,
                vault: Share?,
                lastUseTime: Int64,
                modifyTime: Int64,
                pinned: Bool,
                owner: Bool,
                shared: Bool) {
        var hasher = Hasher()

        self.shareId = shareId
        hasher.combine(shareId)

        self.itemId = itemId
        hasher.combine(itemId)

        self.type = type
        hasher.combine(type)

        self.aliasEmail = aliasEmail
        hasher.combine(aliasEmail)

        self.aliasEnabled = aliasEnabled
        hasher.combine(aliasEnabled)

        highlightableTitle = title
        hasher.combine(title)

        highlightableDetail = detail
        hasher.combine(detail)

        self.url = url
        hasher.combine(url)

        self.vault = vault
        hasher.combine(vault)

        self.lastUseTime = lastUseTime
        hasher.combine(lastUseTime)

        self.modifyTime = modifyTime
        hasher.combine(modifyTime)

        self.pinned = pinned
        hasher.combine(pinned)

        self.owner = owner
        hasher.combine(owner)

        self.shared = shared
        hasher.combine(shared)

        precomputedHash = hasher.finalize()
    }
}

extension ItemSearchResult: ItemThumbnailable {
    public var title: String { highlightableTitle.fullText }
}

extension ItemSearchResult: DateSortable {
    public var dateForSorting: Date {
        Date(timeIntervalSince1970: TimeInterval(max(lastUseTime, modifyTime)))
    }
}

extension ItemSearchResult: AlphabeticalSortable {
    public var alphabeticalSortableString: String { highlightableTitle.fullText }
}

extension ItemSearchResult: PrecomputedHashable {
    public static func == (lhs: ItemSearchResult, rhs: ItemSearchResult) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}
