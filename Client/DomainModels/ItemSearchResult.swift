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
import UIKit

public protocol HighlightableText {
    var fullText: String { get }
    var highlightText: String? { get }
    var isLeadingText: Bool { get }
    var isTrailingText: Bool { get }
}

public enum SearchResultEither: HighlightableText {
    case notMatched(String)
    case matched(SearchResult)

    public var fullText: String {
        switch self {
        case .notMatched(let text):
            return text
        case .matched(let searchResult):
            return searchResult.matchedPhrase
        }
    }

    public var highlightText: String? {
        switch self {
        case .notMatched:
            return nil
        case .matched(let searchResult):
            return searchResult.matchedWord
        }
    }

    public var isLeadingText: Bool {
        switch self {
        case .notMatched:
            return true
        case .matched(let searchResult):
            return searchResult.isLeadingPhrase
        }
    }

    public var isTrailingText: Bool {
        switch self {
        case .notMatched:
            return true
        case .matched(let searchResult):
            return searchResult.isTrailingPhrase
        }
    }
}

public protocol ItemSearchResultProtocol {
    var title: HighlightableText { get }
    var detail: [HighlightableText] { get }
    var vaultName: String { get }
}

public struct ItemSearchResult: ItemIdentifiable, ItemSearchResultProtocol, ItemContentTypeIdentifiable {
    public let shareId: String
    public let itemId: String
    public let type: ItemContentType
    public let title: HighlightableText
    public let detail: [HighlightableText]
    public let vaultName: String

    public init(shareId: String,
                itemId: String,
                type: ItemContentType,
                title: SearchResultEither,
                detail: [SearchResultEither],
                vaultName: String) {
        self.shareId = shareId
        self.itemId = itemId
        self.type = type
        self.title = title
        self.detail = detail
        self.vaultName = vaultName
    }
}

extension ItemSearchResult: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.shareId == rhs.shareId &&
        lhs.itemId == rhs.itemId &&
        lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(shareId)
        hasher.combine(itemId)
        hasher.combine(type)
    }
}

extension ItemSearchResult: Identifiable {
    public var id: String { itemId + shareId }
}
