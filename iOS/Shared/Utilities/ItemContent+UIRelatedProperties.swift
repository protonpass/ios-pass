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
import DesignSystem
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
        }
    }
}

// MARK: - Messages

extension ItemContentType {
    var chipTitle: String {
        switch self {
        case .login:
            "Login".localized
        case .alias:
            "Alias".localized
        case .note:
            "Note".localized
        case .creditCard:
            "Credit card".localized
        }
    }

    var filterTitle: String {
        switch self {
        case .login:
            "Logins".localized
        case .alias:
            "Aliases".localized
        case .note:
            "Notes".localized
        case .creditCard:
            "Credit cards".localized
        }
    }

    var createItemTitle: String {
        switch self {
        case .login:
            "Create a login".localized
        case .alias:
            "Create a Hide My Email alias".localized
        case .creditCard:
            "Create a credit card".localized
        case .note:
            "Create a note".localized
        }
    }

    var creationMessage: String {
        switch self {
        case .login:
            "Login created".localized
        case .alias:
            "Alias created".localized
        case .creditCard:
            "Credit card created".localized
        case .note:
            "Note created".localized
        }
    }

    var restoreMessage: String {
        switch self {
        case .login:
            "Login restored".localized
        case .alias:
            "Alias restored".localized
        case .creditCard:
            "Credit card restored".localized
        case .note:
            "Note restored".localized
        }
    }

    var deleteMessage: String {
        switch self {
        case .login:
            "Login permanently deleted".localized
        case .alias:
            "Alias permanently deleted".localized
        case .creditCard:
            "Credit card permanently deleted".localized
        case .note:
            "Note permanently deleted".localized
        }
    }

    var updateMessage: String {
        switch self {
        case .login:
            "Login updated".localized
        case .alias:
            "Alias updated".localized
        case .creditCard:
            "Credit card updated".localized
        case .note:
            "Note updated".localized
        }
    }
}

extension ItemTypeIdentifiable {
    var trashMessage: String {
        switch type {
        case .login:
            "Login moved to trash".localized
        case .alias:
            "Alias \"%@\" will stop forwarding emails to your mailbox".localized(aliasEmail ?? "")
        case .creditCard:
            "Credit card moved to trash".localized
        case .note:
            "Note moved to trash".localized
        }
    }
}
