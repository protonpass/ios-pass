//
// ItemContent+UIRelatedProperties.swift
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

import Client
import ProtonCore_UIFoundations
import UIComponents
import UIKit

// MARK: - Colors & icons

extension ItemContentType {
    var regularIcon: UIImage {
        switch self {
        case .alias:
            return IconProvider.alias
        case .login:
            return IconProvider.user
        case .note:
            return IconProvider.fileLines
        case .creditCard:
            return PassIcon.passCreditCardOneStripe
        }
    }

    var largeIcon: UIImage {
        switch self {
        case .creditCard:
            return PassIcon.passCreditCardTwoStripes
        default:
            return regularIcon
        }
    }

    var normColor: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNorm
        case .login:
            return PassColor.loginInteractionNorm
        case .note:
            return PassColor.noteInteractionNorm
        case .creditCard:
            return PassColor.cardInteractionNorm
        }
    }

    var normMajor1Color: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMajor1
        case .login:
            return PassColor.loginInteractionNormMajor1
        case .note:
            return PassColor.noteInteractionNormMajor1
        case .creditCard:
            return PassColor.cardInteractionNormMajor1
        }
    }

    var normMajor2Color: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMajor2
        case .login:
            return PassColor.loginInteractionNormMajor2
        case .note:
            return PassColor.noteInteractionNormMajor2
        case .creditCard:
            return PassColor.cardInteractionNormMajor2
        }
    }

    var normMinor1Color: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMinor1
        case .login:
            return PassColor.loginInteractionNormMinor1
        case .note:
            return PassColor.noteInteractionNormMinor1
        case .creditCard:
            return PassColor.cardInteractionNormMinor1
        }
    }

    var normMinor2Color: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMinor2
        case .login:
            return PassColor.loginInteractionNormMinor2
        case .note:
            return PassColor.noteInteractionNormMinor2
        case .creditCard:
            return PassColor.cardInteractionNormMinor2
        }
    }
}

// MARK: - Messages

extension ItemContentType {
    var chipTitle: String {
        switch self {
        case .login:
            return "Login"
        case .alias:
            return "Alias"
        case .note:
            return "Note"
        case .creditCard:
            return "Credit card"
        }
    }

    var createItemTitle: String {
        switch self {
        case .login:
            return "Create a login"
        case .alias:
            return "Create a Hide My Email alias"
        case .creditCard:
            return "Create a credit card"
        case .note:
            return "Create a note"
        }
    }

    var creationMessage: String {
        switch self {
        case .login:
            return "Login created"
        case .alias:
            return "Alias created"
        case .creditCard:
            return "Credit card created"
        case .note:
            return "Note created"
        }
    }

    var restoreMessage: String {
        switch self {
        case .login: return "Login restored"
        case .alias: return "Alias restored"
        case .creditCard: return "Credit card restored"
        case .note: return "Note restored"
        }
    }

    var deleteMessage: String {
        switch self {
        case .login: return "Login permanently deleted"
        case .alias: return "Alias permanently deleted"
        case .creditCard: return "Credit card permanently deleted"
        case .note: return "Note permanently deleted"
        }
    }

    var updateMessage: String {
        switch self {
        case .login: return "Login updated"
        case .alias: return "Alias updated"
        case .creditCard: return "Credit card updated"
        case .note: return "Note updated"
        }
    }
}

extension ItemTypeIdentifiable {
    var trashMessage: String {
        switch type {
        case .login: return "Login moved to trash"
        case .alias: return "Alias \"\(aliasEmail ?? "")\" will stop forwarding emails to your inbox(es)"
        case .creditCard: return "Credit card moved to trash"
        case .note: return "Note moved to trash"
        }
    }
}
