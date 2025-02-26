//
// ItemContentType+Extensions.swift
// Proton Pass - Created on 08/02/2023.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import UIKit

// MARK: - Colors & icons

extension ItemContentType {
    var regularIcon: UIImage {
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
            IconProvider.pencil
        }
    }

    var largeIcon: UIImage {
        switch self {
        case .creditCard:
            PassIcon.passCreditCardTwoStripes
        default:
            regularIcon
        }
    }

    var normColor: UIColor {
        switch self {
        case .alias:
            PassColor.aliasInteractionNorm
        case .login:
            PassColor.loginInteractionNorm
        case .note:
            PassColor.noteInteractionNorm
        case .creditCard:
            PassColor.cardInteractionNorm
        case .identity:
            PassColor.interactionNorm
        case .custom, .sshKey, .wifi:
            PassColor.textNorm
        }
    }

    var normMajor1Color: UIColor {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMajor1
        case .login:
            PassColor.loginInteractionNormMajor1
        case .note:
            PassColor.noteInteractionNormMajor1
        case .creditCard:
            PassColor.cardInteractionNormMajor1
        case .identity:
            PassColor.interactionNormMajor1
        case .custom, .sshKey, .wifi:
            PassColor.textNorm
        }
    }

    var normMajor2Color: UIColor {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMajor2
        case .login:
            PassColor.loginInteractionNormMajor2
        case .note:
            PassColor.noteInteractionNormMajor2
        case .creditCard:
            PassColor.cardInteractionNormMajor2
        case .identity:
            PassColor.interactionNormMajor2
        case .custom, .sshKey, .wifi:
            PassColor.textNorm
        }
    }

    var normMinor1Color: UIColor {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMinor1
        case .login:
            PassColor.loginInteractionNormMinor1
        case .note:
            PassColor.noteInteractionNormMinor1
        case .creditCard:
            PassColor.cardInteractionNormMinor1
        case .identity:
            PassColor.interactionNormMinor1
        case .custom, .sshKey, .wifi:
            PassColor.customItemBackground
        }
    }

    var normMinor2Color: UIColor {
        switch self {
        case .alias:
            PassColor.aliasInteractionNormMinor2
        case .login:
            PassColor.loginInteractionNormMinor2
        case .note:
            PassColor.noteInteractionNormMinor2
        case .creditCard:
            PassColor.cardInteractionNormMinor2
        case .identity:
            PassColor.interactionNormMinor2
        case .custom, .sshKey, .wifi:
            PassColor.customItemBackground
        }
    }
}

// MARK: - Messages

extension ItemContentType {
    var chipTitle: String {
        switch self {
        case .login:
            #localized("Login")
        case .alias:
            #localized("Alias")
        case .note:
            #localized("Note")
        case .creditCard:
            #localized("Card")
        case .identity:
            #localized("Identity")
        case .sshKey:
            #localized("SSH key")
        case .wifi:
            #localized("WiFi network")
        case .custom:
            #localized("Custom item")
        }
    }

    var filterTitle: String {
        switch self {
        case .login:
            #localized("Logins")
        case .alias:
            #localized("Aliases")
        case .note:
            #localized("Notes")
        case .creditCard:
            #localized("Credit cards")
        case .identity:
            #localized("Identities")
        case .sshKey:
            #localized("SSH keys")
        case .wifi:
            #localized("WiFi networks")
        case .custom:
            #localized("Custom items")
        }
    }

    var filterMessage: String {
        switch self {
        case .login:
            #localized("Filtered by logins. Trashed items aren't shown.")
        case .alias:
            #localized("Filtered by aliases. Trashed items aren't shown.")
        case .note:
            #localized("Filtered by notes. Trashed items aren't shown.")
        case .creditCard:
            #localized("Filtered by credit cards. Trashed items aren't shown.")
        case .identity:
            #localized("Filtered by identities. Trashed items aren't shown.")
        case .custom, .sshKey, .wifi:
            #localized("Filtered by custom items. Trashed items aren't shown.")
        }
    }

    var createItemTitle: String {
        switch self {
        case .login:
            #localized("Create a login")
        case .alias:
            #localized("Create a Hide My Email alias")
        case .creditCard:
            #localized("Create a card")
        case .note:
            #localized("Create a note")
        case .identity:
            #localized("Create an identity")
        case .custom, .sshKey, .wifi:
            #localized("Create a custom item")
        }
    }

    var creationMessage: String {
        switch self {
        case .login:
            #localized("Login created")
        case .alias:
            #localized("Alias created")
        case .creditCard:
            #localized("Credit card created")
        case .note:
            #localized("Note created")
        case .identity:
            #localized("Identity created")
        case .sshKey:
            #localized("SSH key created")
        case .wifi:
            #localized("WiFi network created")
        case .custom:
            #localized("Custom item created")
        }
    }

    var openMessage: String {
        switch self {
        case .login:
            #localized("Open login")
        case .alias:
            #localized("Open alias")
        case .creditCard:
            #localized("Open credit card")
        case .note:
            #localized("Open note")
        case .identity:
            #localized("Open identity")
        case .sshKey:
            #localized("Open SSH key")
        case .wifi:
            #localized("Open WiFi network")
        case .custom:
            #localized("Open custom item")
        }
    }

    var restoreMessage: String {
        switch self {
        case .login:
            #localized("Login restored")
        case .alias:
            #localized("Alias restored")
        case .creditCard:
            #localized("Credit card restored")
        case .note:
            #localized("Note restored")
        case .identity:
            #localized("Identity restored")
        case .sshKey:
            #localized("SSH key restored")
        case .wifi:
            #localized("WiFi network restored")
        case .custom:
            #localized("Custom item restored")
        }
    }

    var deleteMessage: String {
        switch self {
        case .login:
            #localized("Login permanently deleted")
        case .alias:
            #localized("Alias permanently deleted")
        case .creditCard:
            #localized("Credit card permanently deleted")
        case .note:
            #localized("Note permanently deleted")
        case .identity:
            #localized("Identity permanently deleted")
        case .sshKey:
            #localized("SSH key permanently deleted")
        case .wifi:
            #localized("WiFi network permanently deleted")
        case .custom:
            #localized("Custom item permanently deleted")
        }
    }

    var updateMessage: String {
        switch self {
        case .login:
            #localized("Login updated")
        case .alias:
            #localized("Alias updated")
        case .creditCard:
            #localized("Credit card updated")
        case .note:
            #localized("Note updated")
        case .identity:
            #localized("Identity updated")
        case .sshKey:
            #localized("SSH key updated")
        case .wifi:
            #localized("WiFi network updated")
        case .custom:
            #localized("Custom item updated")
        }
    }
}
