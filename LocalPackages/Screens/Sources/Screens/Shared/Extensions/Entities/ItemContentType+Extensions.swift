//
// ItemContentType+Extensions.swift
// Proton Pass - Created on 17/07/2026.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

// MARK: - Colors & icons

public extension ItemContentType {
    var regularIcon: Image {
        switch self {
        case .alias:
            IconProvider.alias

        case .login:
            IconProvider.user

        case .note:
            IconProvider.fileLines

        case .creditCard:
            PassIcon.passCreditCardOneStripe

        case .identity:
            IconProvider.cardIdentity

        case .custom, .sshKey, .wifi:
            IconProvider.wrench
        }
    }

    var largeIcon: Image {
        switch self {
        case .creditCard:
            PassIcon.passCreditCardTwoStripes

        default:
            regularIcon
        }
    }

    var normColor: Color {
        switch self {
        case .alias:
            PassColor.aliasInteractionNorm

        case .login:
            PassColor.loginInteractionNorm

        case .note:
            PassColor.noteInteractionNorm

        case .creditCard:
            PassColor.cardInteractionNorm

        case .custom, .identity, .sshKey, .wifi:
            PassColor.interactionNorm
        }
    }

    var normMajor1Color: Color {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMajor1

        case .login:
            PassColor.loginInteractionNormMajor1

        case .note:
            PassColor.noteInteractionNormMajor1

        case .creditCard:
            PassColor.cardInteractionNormMajor1

        case .custom, .identity, .sshKey, .wifi:
            PassColor.interactionNormMajor1
        }
    }

    var normMajor1UIColor: UIColor {
        switch self {
        case .alias:
            PassUIColor.aliasInteractionNormMajor1

        case .login:
            PassUIColor.loginInteractionNormMajor1

        case .note:
            PassUIColor.noteInteractionNormMajor1

        case .creditCard:
            PassUIColor.cardInteractionNormMajor1

        case .custom, .identity, .sshKey, .wifi:
            PassUIColor.interactionNormMajor1
        }
    }

    var normMajor2Color: Color {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMajor2

        case .login:
            PassColor.loginInteractionNormMajor2

        case .note:
            PassColor.noteInteractionNormMajor2

        case .creditCard:
            PassColor.cardInteractionNormMajor2

        case .custom, .identity, .sshKey, .wifi:
            PassColor.interactionNormMajor2
        }
    }

    var normMinor1Color: Color {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMinor1

        case .login:
            PassColor.loginInteractionNormMinor1

        case .note:
            PassColor.noteInteractionNormMinor1

        case .creditCard:
            PassColor.cardInteractionNormMinor1

        case .custom, .identity, .sshKey, .wifi:
            PassColor.interactionNormMinor1
        }
    }

    var normMinor2Color: Color {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMinor2

        case .login:
            PassColor.loginInteractionNormMinor2

        case .note:
            PassColor.noteInteractionNormMinor2

        case .creditCard:
            PassColor.cardInteractionNormMinor2

        case .custom, .identity, .sshKey, .wifi:
            PassColor.interactionNormMinor2
        }
    }
}

// MARK: Thumbnail colors

public extension ItemContentType {
    var thumbnailTintColor: Color {
        switch self {
        case .custom, .sshKey, .wifi:
            PassColor.textNorm

        default:
            normMajor2Color
        }
    }

    var thumbnailBackgroundColor: Color {
        switch self {
        case .custom, .sshKey, .wifi:
            PassColor.customItemBackground

        default:
            normMinor1Color
        }
    }

    var thumbnailAlternativeBackgroundColor: Color {
        switch self {
        case .custom, .sshKey, .wifi:
            PassColor.customItemBackground

        default:
            normMinor2Color
        }
    }
}

// MARK: - Messages

public extension ItemContentType {
    var chipTitle: String {
        switch self {
        case .login:
            #localized("Login", bundle: .module)

        case .alias:
            #localized("Alias", bundle: .module)

        case .note:
            #localized("Note", bundle: .module)

        case .creditCard:
            #localized("Card", bundle: .module)

        case .identity:
            #localized("Identity", bundle: .module)

        case .sshKey:
            #localized("SSH key", bundle: .module)

        case .wifi:
            #localized("WiFi network", bundle: .module)

        case .custom:
            #localized("Custom item", bundle: .module)
        }
    }

    var filterTitle: String {
        switch self {
        case .login:
            #localized("Logins", bundle: .module)

        case .alias:
            #localized("Aliases", bundle: .module)

        case .note:
            #localized("Notes", bundle: .module)

        case .creditCard:
            #localized("Credit cards", bundle: .module)

        case .identity:
            #localized("Identities", bundle: .module)

        case .sshKey:
            #localized("SSH keys", bundle: .module)

        case .wifi:
            #localized("WiFi networks", bundle: .module)

        case .custom:
            #localized("Custom items", bundle: .module)
        }
    }

    var filterMessage: String {
        switch self {
        case .login:
            #localized("Filtered by logins. Trashed items aren't shown.", bundle: .module)

        case .alias:
            #localized("Filtered by aliases. Trashed items aren't shown.", bundle: .module)

        case .note:
            #localized("Filtered by notes. Trashed items aren't shown.", bundle: .module)

        case .creditCard:
            #localized("Filtered by credit cards. Trashed items aren't shown.", bundle: .module)

        case .identity:
            #localized("Filtered by identities. Trashed items aren't shown.", bundle: .module)

        case .custom, .sshKey, .wifi:
            #localized("Filtered by custom items. Trashed items aren't shown.", bundle: .module)
        }
    }

    var createItemTitle: String {
        switch self {
        case .login:
            #localized("Create a login", bundle: .module)

        case .alias:
            #localized("Create a Hide My Email alias", bundle: .module)

        case .creditCard:
            #localized("Create a card", bundle: .module)

        case .note:
            #localized("Create a note", bundle: .module)

        case .identity:
            #localized("Create an identity", bundle: .module)

        case .custom, .sshKey, .wifi:
            #localized("Create a custom item", bundle: .module)
        }
    }

    var creationMessage: String {
        switch self {
        case .login:
            #localized("Login created", bundle: .module)

        case .alias:
            #localized("Alias created", bundle: .module)

        case .creditCard:
            #localized("Credit card created", bundle: .module)

        case .note:
            #localized("Note created", bundle: .module)

        case .identity:
            #localized("Identity created", bundle: .module)

        case .sshKey:
            #localized("SSH key created", bundle: .module)

        case .wifi:
            #localized("WiFi network created", bundle: .module)

        case .custom:
            #localized("Custom item created", bundle: .module)
        }
    }

    var openMessage: String {
        switch self {
        case .login:
            #localized("Open login", bundle: .module)

        case .alias:
            #localized("Open alias", bundle: .module)

        case .creditCard:
            #localized("Open credit card", bundle: .module)

        case .note:
            #localized("Open note", bundle: .module)

        case .identity:
            #localized("Open identity", bundle: .module)

        case .sshKey:
            #localized("Open SSH key", bundle: .module)

        case .wifi:
            #localized("Open WiFi network", bundle: .module)

        case .custom:
            #localized("Open custom item", bundle: .module)
        }
    }

    var restoreMessage: String {
        switch self {
        case .login:
            #localized("Login restored", bundle: .module)

        case .alias:
            #localized("Alias restored", bundle: .module)

        case .creditCard:
            #localized("Credit card restored", bundle: .module)

        case .note:
            #localized("Note restored", bundle: .module)

        case .identity:
            #localized("Identity restored", bundle: .module)

        case .sshKey:
            #localized("SSH key restored", bundle: .module)

        case .wifi:
            #localized("WiFi network restored", bundle: .module)

        case .custom:
            #localized("Custom item restored", bundle: .module)
        }
    }

    var deleteMessage: String {
        switch self {
        case .login:
            #localized("Login permanently deleted", bundle: .module)

        case .alias:
            #localized("Alias permanently deleted", bundle: .module)

        case .creditCard:
            #localized("Credit card permanently deleted", bundle: .module)

        case .note:
            #localized("Note permanently deleted", bundle: .module)

        case .identity:
            #localized("Identity permanently deleted", bundle: .module)

        case .sshKey:
            #localized("SSH key permanently deleted", bundle: .module)

        case .wifi:
            #localized("WiFi network permanently deleted", bundle: .module)

        case .custom:
            #localized("Custom item permanently deleted", bundle: .module)
        }
    }

    var updateMessage: String {
        switch self {
        case .login:
            #localized("Login updated", bundle: .module)

        case .alias:
            #localized("Alias updated", bundle: .module)

        case .creditCard:
            #localized("Credit card updated", bundle: .module)

        case .note:
            #localized("Note updated", bundle: .module)

        case .identity:
            #localized("Identity updated", bundle: .module)

        case .sshKey:
            #localized("SSH key updated", bundle: .module)

        case .wifi:
            #localized("WiFi network updated", bundle: .module)

        case .custom:
            #localized("Custom item updated", bundle: .module)
        }
    }
}
