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
import Foundation

/// Items that live in memory for search purpose
public struct SearchableItem: ItemTypeIdentifiable, Equatable, Hashable {
    public let shareId: String
    public let itemId: String
    public let vault: Share? // Optional because we only show vault when there're more than 1 vault
    public let type: ItemContentType
    public let owner: Bool
    public let shared: Bool
    public let aliasEmail: String?
    public let aliasEnabled: Bool
    public let name: String
    public let note: String
    public let url: String?
    // `totpUri` to conform to ItemTypeIdentifiable protocol
    // but always nil because not applicable to search results
    public var totpUri: String?
    public let hasTotpUri: Bool
    public let requiredExtras: [String] // E.g: Username for login items
    public let optionalExtras: [String] // E.g: URLs for login items
    public let lastUseTime: Int64
    public let modifyTime: Int64
    public let pinned: Bool
    public let hasEmail: Bool
    public let hasUsername: Bool
    public let hasPassword: Bool

    public init(from item: SymmetricallyEncryptedItem,
                symmetricKey: SymmetricKey,
                allVaults: [Share]) throws {
        let itemContent = try item.getItemContent(symmetricKey: symmetricKey)

        self.init(from: itemContent, allVaults: allVaults)
    }

    // swiftlint:disable:next function_body_length
    public init(from itemContent: ItemContent,
                allVaults: [Share]) {
        itemId = itemContent.item.itemID
        shareId = itemContent.shareId

        let linkedVault = allVaults.first { $0.shareId == itemContent.shareId }
        vault = allVaults.count > 1 ? linkedVault : nil

        owner = linkedVault?.isOwner ?? false
        shared = itemContent.shared

        type = itemContent.contentData.type
        aliasEmail = itemContent.item.aliasEmail
        aliasEnabled = itemContent.item.isAliasEnabled
        name = itemContent.name.trimmingCharacters(in: .whitespacesAndNewlines)
        note = itemContent.note.trimmingCharacters(in: .whitespacesAndNewlines)

        var optionalExtras: [String] = []
        var hasTotpUri = false
        var extraCustomFields: [CustomField] = []
        var customSections: [CustomSection] = []
        var hasEmail = false
        var hasUsername = false
        var hasPassword = false

        switch itemContent.contentData {
        case let .login(data):
            url = data.urls.first
            requiredExtras = [data.email, data.username]
            optionalExtras = data.urls
            hasTotpUri = !data.totpUri.isEmpty
            hasEmail = !data.email.isEmpty
            hasUsername = !data.username.isEmpty
            hasPassword = !data.password.isEmpty

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

            extraCustomFields += data.extraAddressDetails
            extraCustomFields += data.extraPersonalDetails
            extraCustomFields += data.extraContactDetails
            extraCustomFields += data.extraWorkDetails

            customSections = data.extraSections

        case let .sshKey(data):
            url = nil
            requiredExtras = []
            customSections = data.extraSections

        case let .wifi(data):
            url = nil
            requiredExtras = []
            customSections = data.extraSections

        case let .custom(data):
            url = nil
            requiredExtras = []
            customSections = data.sections

        default:
            url = nil
            requiredExtras = []
            optionalExtras = []
        }

        let customFields = itemContent.customFields + extraCustomFields
        for field in customFields where field.type == .text {
            optionalExtras.append("\(field.title): \(field.content)")
        }

        for section in customSections {
            optionalExtras.append(section.title)
            for field in section.content where field.type == .text {
                optionalExtras.append("\(field.title): \(field.content)")
            }
        }

        if let simpleLoginNote = itemContent.simpleLoginNote {
            optionalExtras.append(simpleLoginNote)
        }

        lastUseTime = itemContent.item.lastUseTime ?? 0
        modifyTime = itemContent.item.modifyTime
        pinned = itemContent.item.pinned
        self.optionalExtras = optionalExtras
        self.hasTotpUri = hasTotpUri
        self.hasEmail = hasEmail
        self.hasUsername = hasUsername
        self.hasPassword = hasPassword
    }
}

private extension SearchableItem {
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
                     pinned: pinned,
                     owner: owner,
                     shared: shared,
                     hasEmail: hasEmail,
                     hasUsername: hasUsername,
                     hasPassword: hasPassword)
    }

    var toItemSearchResult: ItemSearchResult {
        ItemSearchResult(shareId: shareId,
                         itemId: itemId,
                         type: type,
                         aliasEmail: aliasEmail,
                         aliasEnabled: aliasEnabled,
                         title: .notMatched(name),
                         detail: [.notMatched(requiredExtras.first ?? "")],
                         url: url,
                         vault: vault,
                         lastUseTime: lastUseTime,
                         modifyTime: modifyTime,
                         pinned: pinned,
                         owner: owner,
                         shared: shared,
                         hasEmail: hasEmail,
                         hasUsername: hasUsername,
                         hasPassword: hasPassword)
    }
}

public extension SearchableItem {
    var toSearchEntryUiModel: SearchEntryUiModel {
        SearchEntryUiModel(itemId: itemId,
                           shareId: shareId,
                           type: type,
                           title: name,
                           url: url,
                           description: note)
    }
}

public extension [SearchableItem] {
    // While this function has no async operations but they're quite resource demanding
    // when dealing with a large amount of data
    // so we make it async in order to execute it concurrently out of the main thread
    func result(for term: String) async throws -> [ItemSearchResult] {
        try compactMap {
            #if DEBUG
            if Thread.isMainThread {
                assertionFailure("Should not search in main thread")
            }
            #endif
            try Task.checkCancellation()
            return $0.result(for: term)
        }
    }

    var toItemSearchResults: [ItemSearchResult] {
        self.map(\.toItemSearchResult)
    }
}
