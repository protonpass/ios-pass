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

public enum SpotlightSearchableContent: Int, Codable, CaseIterable, Sendable {
    case title = 0
    case titleAndNote = 1
    case allExceptSensitiveData = 2

    var includeNote: Bool {
        if case .title = self {
            return false
        }
        return true
    }

    var includeCustomData: Bool {
        if case .allExceptSensitiveData = self {
            return true
        }
        return false
    }
}

public enum SpotlightSearchableVaults: Int, Codable, CaseIterable, Sendable {
    case all = 0
    case selected = 1
}

public protocol SpotlightSettingsProvider: Sendable {
    var spotlightEnabled: Bool { get }
    var spotlightSearchableContent: SpotlightSearchableContent { get }
    var spotlightSearchableVaults: SpotlightSearchableVaults { get }
}

public extension ItemContent {
    var spotlightDomainId: String {
        type.debugDescription
    }

    func toSearchableItem(content: SpotlightSearchableContent) throws -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = name
        // "displayName" is required by iOS 17
        // https://forums.developer.apple.com/forums/thread/734996?answerId=763586022#763586022
        attributeSet.displayName = name

        var contents = [String?]()

        if content.includeNote {
            contents.append(note)
        }

        if content.includeCustomData {
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

            let customFieldValues = customFields
                .filter { $0.type == .text }
                .map { "\($0.title): \($0.content)" }

            contents.append(contentsOf: customFieldValues)
        }

        attributeSet.contentDescription = contents.compactMap { $0 }.joined(separator: "\n")
        let id = try ids.serializeBase64()
        return .init(uniqueIdentifier: id,
                     domainIdentifier: spotlightDomainId,
                     attributeSet: attributeSet)
    }
}
