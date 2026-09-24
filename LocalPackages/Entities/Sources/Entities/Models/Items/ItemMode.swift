//
// ItemMode.swift
// Proton Pass - Created on 16/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public enum ItemMode: Equatable, Hashable {
    case create(ItemCreationType)
    case clone(ItemContent)
    case edit(ItemContent)

    public var itemContent: ItemContent? {
        switch self {
        case let .clone(content), let .edit(content):
            content

        default:
            nil
        }
    }

    public var isEditMode: Bool {
        switch self {
        case .edit:
            true

        default:
            false
        }
    }

    public var canChangeVault: Bool {
        switch self {
        case .clone, .create:
            true

        default:
            false
        }
    }
}

public enum ItemCreationType: Equatable, Hashable {
    case note(title: String, note: String)
    case alias
    // swiftlint:disable:next enum_case_associated_values_count
    case login(title: String? = nil,
               email: String? = nil,
               password: String? = nil,
               url: String? = nil,
               note: String? = nil,
               totpUri: String? = nil,
               autofill: Bool,
               passkeyCredentialRequest: PasskeyCredentialRequest? = nil)
    case creditCard
    case identity
    case sshKey
    case wifi
    case custom(CustomItemTemplate)

    public var itemContentType: ItemContentType {
        switch self {
        case .note:
            .note

        case .alias:
            .alias

        case .login:
            .login

        case .creditCard:
            .creditCard

        case .identity:
            .identity

        case .sshKey:
            .sshKey

        case .wifi:
            .wifi

        case .custom:
            .custom
        }
    }
}
