//
// PassColor.swift
// Proton Pass - Created on 05/04/2023.
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

// swiftlint:disable force_unwrapping
import UIKit

public enum PassColor: Sendable {}

private extension PassColor {
    static func color(named: String) -> UIColor {
        UIColor(named: named, in: .module, compatibleWith: nil)!
    }
}

public extension PassColor {
    static let inputBackgroundNorm = Self
        .color(named: "InputBackgroundNorm") // Self.color(named: , in: .module, compatibleWith: nil)!
    static let inputBorderNorm = Self.color(named: "InputBorderNorm")
    static let borderWeak = Self.color(named: "BorderWeak")
    static let interactionNorm = Self.color(named: "InteractionNorm")
    static let interactionNormMajor1 = Self.color(named: "InteractionNormMajor1")
    static let interactionNormMajor2 = Self.color(named: "InteractionNormMajor2")
    static let interactionNormMinor1 = Self.color(named: "InteractionNormMinor1")
    static let interactionNormMinor2 = Self.color(named: "InteractionNormMinor2")
}

// MARK: - Background

public extension PassColor {
    static let backdrop = Self.color(named: "Backdrop")
    static let backgroundMedium = Self.color(named: "BackgroundMedium")
    static let backgroundNorm = Self.color(named: "BackgroundNorm")
    static let backgroundStrong = Self.color(named: "BackgroundStrong")
    static let backgroundWeak = Self.color(named: "BackgroundWeak")
    static let tabBarBackground = Self.color(named: "TabBarBackground")
}

// MARK: - Items

public extension PassColor {
    static let aliasInteractionNorm = Self.color(named: "AliasInteractionNorm")
    static let aliasInteractionNormMajor1 = Self.color(named: "AliasInteractionNormMajor1")
    static let aliasInteractionNormMajor2 = Self.color(named: "AliasInteractionNormMajor2")
    static let aliasInteractionNormMinor1 = Self.color(named: "AliasInteractionNormMinor1")
    static let aliasInteractionNormMinor2 = Self.color(named: "AliasInteractionNormMinor2")

    static let cardInteractionNorm = Self.color(named: "CardInteractionNorm")
    static let cardInteractionNormMajor1 = Self.color(named: "CardInteractionNormMajor1")
    static let cardInteractionNormMajor2 = Self.color(named: "CardInteractionNormMajor2")
    static let cardInteractionNormMinor1 = Self.color(named: "CardInteractionNormMinor1")
    static let cardInteractionNormMinor2 = Self.color(named: "CardInteractionNormMinor2")

    static let loginInteractionNorm = Self.color(named: "LoginInteractionNorm")
    static let loginInteractionNormMajor1 = Self.color(named: "LoginInteractionNormMajor1")
    static let loginInteractionNormMajor2 = Self.color(named: "LoginInteractionNormMajor2")
    static let loginInteractionNormMinor1 = Self.color(named: "LoginInteractionNormMinor1")
    static let loginInteractionNormMinor2 = Self.color(named: "LoginInteractionNormMinor2")

    static let noteInteractionNorm = Self.color(named: "NoteInteractionNorm")
    static let noteInteractionNormMajor1 = Self.color(named: "NoteInteractionNormMajor1")
    static let noteInteractionNormMajor2 = Self.color(named: "NoteInteractionNormMajor2")
    static let noteInteractionNormMinor1 = Self.color(named: "NoteInteractionNormMinor1")
    static let noteInteractionNormMinor2 = Self.color(named: "NoteInteractionNormMinor2")

    static let passwordInteractionNorm = Self.color(named: "PasswordInteractionNorm")
    static let passwordInteractionNormMajor1 = Self.color(named: "PasswordInteractionNormMajor1")
    static let passwordInteractionNormMajor2 = Self.color(named: "PasswordInteractionNormMajor2")
    static let passwordInteractionNormMinor1 = Self.color(named: "PasswordInteractionNormMinor1")
    static let passwordInteractionNormMinor2 = Self.color(named: "PasswordInteractionNormMinor2")

    static let customItemBackground = Self.color(named: "CustomItemBackground")
}

// MARK: - Signals

public extension PassColor {
    static let signalDanger = Self.color(named: "SignalDanger")
    static let signalInfo = Self.color(named: "SignalInfo")
    static let signalSuccess = Self.color(named: "SignalSuccess")
    static let signalWarning = Self.color(named: "SignalWarning")
}

// MARK: - Texts

public extension PassColor {
    static let textDisabled = Self.color(named: "TextDisabled")
    static let textHint = Self.color(named: "TextHint")
    static let textInvert = Self.color(named: "TextInvert")
    static let textNorm = Self.color(named: "TextNorm")
    static let textWeak = Self.color(named: "TextWeak")
}

// MARK: - Vaults

public extension PassColor {
    static let vaultChestnutRose = Self.color(named: "VaultChestnutRose")
    static let vaultDeYork = Self.color(named: "VaultDeYork")
    static let vaultHeliotrope = Self.color(named: "VaultHeliotrope")
    static let vaultJordyBlue = Self.color(named: "VaultJordyBlue")
    static let vaultLavenderMagenta = Self.color(named: "VaultLavenderMagenta")
    static let vaultMarigoldYellow = Self.color(named: "VaultMarigoldYellow")
    static let vaultMauvelous = Self.color(named: "VaultMauvelous")
    static let vaultMercury = Self.color(named: "VaultMercury")
    static let vaultPorsche = Self.color(named: "VaultPorsche")
    static let vaultWaterLeaf = Self.color(named: "VaultWaterLeaf")
}

// swiftlint:enable force_unwrapping
