//
// CustomField.swift
// Proton Pass - Created on 24/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Foundation

public enum CustomFieldType: CaseIterable, Equatable, Hashable, Sendable {
    case text, totp, hidden, timestamp

    public var defaultContent: String {
        if case .timestamp = self {
            "\(Int(Date.now.timeIntervalSince1970))"
        } else {
            ""
        }
    }
}

public enum CustomFieldUpdate: Sendable {
    case title(String)
    case content(String)
}

public struct CustomField: Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let type: CustomFieldType
    public var content: String

    public init(id: String = UUID().uuidString,
                title: String,
                type: CustomFieldType,
                content: String) {
        self.id = id
        self.title = title
        self.type = type
        self.content = content
    }

    init(from extraField: ProtonPassItemV1_ExtraField) {
        id = UUID().uuidString
        title = extraField.fieldName
        switch extraField.content {
        case let .text(extraText):
            type = .text
            content = extraText.content

        case let .totp(extraTotp):
            type = .totp
            content = extraTotp.totpUri

        case let .hidden(extraHidden):
            type = .hidden
            content = extraHidden.content

        case let .timestamp(extraTimestamp):
            type = .timestamp
            if extraTimestamp.hasTimestamp {
                content = String(extraTimestamp.timestamp.seconds)
            } else {
                content = ""
            }

        case .none:
            type = .text
            content = ""
        }
    }

    public func update(from update: CustomFieldUpdate) -> CustomField {
        let updatedTitle: String
        let updatedContent: String
        switch update {
        case let .title(newTitle):
            updatedTitle = newTitle
            updatedContent = content
        case let .content(newContent):
            updatedTitle = title
            updatedContent = newContent
        }
        return .init(id: id, title: updatedTitle, type: type, content: updatedContent)
    }
}
