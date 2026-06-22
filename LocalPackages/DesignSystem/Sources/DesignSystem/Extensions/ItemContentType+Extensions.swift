//
// ItemContentType+Extensions.swift
// Proton Pass - Created on 08/06/2023.
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

import Entities
import ProtonCoreUIFoundations
import SwiftUI

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
