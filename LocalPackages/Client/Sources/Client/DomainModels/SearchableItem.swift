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

// swiftlint:disable cyclomatic_complexity
/// Items that live in memory for search purpose
public struct SearchableItem: ItemTypeIdentifiable, Equatable {
    public let shareId: String
    public let itemId: String
    public let vault: Vault? // Optional because we only show vault when there're more than 1 vault
    public let type: ItemContentType
    public let aliasEmail: String?
    public let aliasEnabled: Bool
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
        let itemContent = try item.getItemContent(symmetricKey: symmetricKey)

        self.init(from: itemContent, allVaults: allVaults)
    }

    public init(from itemContent: ItemContent,
                allVaults: [Vault]) {
        itemId = itemContent.item.itemID
        shareId = itemContent.shareId

        if allVaults.count > 1 {
            vault = allVaults.first { $0.shareId == itemContent.shareId }
        } else {
            vault = nil
        }

        type = itemContent.contentData.type
        aliasEmail = itemContent.item.aliasEmail
        aliasEnabled = itemContent.item.isAliasEnabled
        name = itemContent.name
        note = itemContent.note

        var optionalExtras: [String] = []

        switch itemContent.contentData {
        case let .login(data):
            url = data.urls.first
            requiredExtras = [data.email, data.username]
            optionalExtras = data.urls
        case let .identity(data):
            url = nil
            requiredExtras = [data.email, data.fullName]
            optionalExtras = [
                data.birthdate,
                data.lastName,
                data.county,
                data.firstName,
                data.facebook,
                data.floor,
                data.gender,
                data.instagram,
                data.middleName,
                data.personalWebsite,
                data.reddit,
                data.workEmail,
                data.workPhoneNumber,
                data.yahoo,
                data.city,
                data.company,
                data.countryOrRegion,
                data.jobTitle,
                data.licenseNumber,
                data.organization,
                data.passportNumber,
                data.phoneNumber,
                data.secondPhoneNumber,
                data.socialSecurityNumber,
                data.stateOrProvince,
                data.streetAddress,
                data.website,
                data.linkedIn,
                data.xHandle,
                data.zipOrPostalCode
            ]

            for customField in data.extraAddressDetails where customField.type == .text {
                optionalExtras.append("\(customField.title): \(customField.content)")
            }
            for customField in data.extraPersonalDetails where customField.type == .text {
                optionalExtras.append("\(customField.title): \(customField.content)")
            }
            for customField in data.extraContactDetails where customField.type == .text {
                optionalExtras.append("\(customField.title): \(customField.content)")
            }
            for customField in data.extraWorkDetails where customField.type == .text {
                optionalExtras.append("\(customField.title): \(customField.content)")
            }
            for section in data.extraSections {
                for customField in section.content where customField.type == .text {
                    optionalExtras.append("\(customField.title): \(customField.content)")
                }
            }
        default:
            url = nil
            requiredExtras = []
            optionalExtras = []
        }

        for customField in itemContent.customFields where customField.type == .text {
            optionalExtras.append("\(customField.title): \(customField.content)")
        }

        lastUseTime = itemContent.item.lastUseTime ?? 0
        modifyTime = itemContent.item.modifyTime
        pinned = itemContent.item.pinned
        self.optionalExtras = optionalExtras
    }
}

extension SearchableItem {
    func result(for term: String) -> ItemSearchResult? {
        let title: SearchResultEither = if let result = SearchUtils.search(query: term, in: name) {
            .matched(result)
        } else {
            .notMatched(name)
        }

        var detail = [SearchResultEither]()

        if let aliasEmail {
            if let result = SearchUtils.search(query: term, in: aliasEmail) {
                detail.append(.matched(result))
            }
        }

        if let result = SearchUtils.search(query: term, in: note) {
            detail.append(.matched(result))
        } else {
            detail.append(.notMatched(note))
        }

        for extra in requiredExtras {
            if let result = SearchUtils.search(query: term, in: extra) {
                detail.append(.matched(result))
            } else {
                detail.append(.notMatched(extra))
            }
        }

        for extra in optionalExtras {
            if let result = SearchUtils.search(query: term, in: extra) {
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
                     aliasEnabled: aliasEnabled,
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
                         aliasEnabled: aliasEnabled,
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

// swiftlint:enable cyclomatic_complexity
