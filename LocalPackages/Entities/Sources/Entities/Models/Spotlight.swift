//
// Spotlight.swift
// Proton Pass - Created on 29/01/2024.
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

import CoreSpotlight
import Foundation

public enum SpotlightSearchableItemType: Sendable {
    case all
    case precise(ItemContentType)
}

public extension ItemContent {
    var spotlightDomainId: String {
        type.debugDescription
    }

    func toSearchableItem() throws -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = name
        // "displayName" is required by iOS 17
        // https://forums.developer.apple.com/forums/thread/734996?answerId=763586022#763586022
        attributeSet.displayName = name

        var contents = [String?]()

        // Index custom data first
        switch contentData {
        case .alias:
            contents.append(aliasEmail)
        case let .login(data):
            contents.append(contentsOf: [data.username] + data.urls)
        case let .creditCard(data):
            contents.append(contentsOf: [data.cardholderName, data.expirationDate])
        case .note:
            break
        }

        // Then index common data like note & custom fields
        contents.append(note)
        let customFieldValues = customFields
            .filter { $0.type == .text }
            .map { "\($0.title): \($0.content)" }
        contents.append(contentsOf: customFieldValues)

        attributeSet.contentDescription = contents.compactMap { $0 }.joined(separator: "\n")
        let id = try ids.serializeBase64()
        return .init(uniqueIdentifier: id,
                     domainIdentifier: spotlightDomainId,
                     attributeSet: attributeSet)
    }
}
