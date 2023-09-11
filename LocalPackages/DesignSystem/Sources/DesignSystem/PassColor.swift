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

public enum PassColor {}

private extension PassColor {
    static func color(named: String) -> UIColor {
        UIColor(named: named, in: .module, compatibleWith: nil)!
    }
}

public extension PassColor {
    static var inputBackgroundNorm = Self
        .color(named: "InputBackgroundNorm") // Self.color(named: , in: .module, compatibleWith: nil)!
    static var inputBorderNorm = Self.color(named: "InputBorderNorm")

    static var interactionNorm = Self.color(named: "InteractionNorm")
    static var interactionNormMajor1 = Self.color(named: "InteractionNormMajor1")
    static var interactionNormMajor2 = Self.color(named: "InteractionNormMajor2")
    static var interactionNormMinor1 = Self.color(named: "InteractionNormMinor1")
    static var interactionNormMinor2 = Self.color(named: "InteractionNormMinor2")
}

// MARK: - Background

public extension PassColor {
    static var backdrop = Self.color(named: "Backdrop")
    static var backgroundMedium = Self.color(named: "BackgroundMedium")
    static var backgroundNorm = Self.color(named: "BackgroundNorm")
    static var backgroundStrong = Self.color(named: "BackgroundStrong")
    static var backgroundWeak = Self.color(named: "BackgroundWeak")
    static var tabBarBackground = Self.color(named: "TabBarBackground")
}

// MARK: - Items

public extension PassColor {
    static var aliasInteractionNorm = Self.color(named: "AliasInteractionNorm")
    static var aliasInteractionNormMajor1 = Self.color(named: "AliasInteractionNormMajor1")
    static var aliasInteractionNormMajor2 = Self.color(named: "AliasInteractionNormMajor2")
    static var aliasInteractionNormMinor1 = Self.color(named: "AliasInteractionNormMinor1")
    static var aliasInteractionNormMinor2 = Self.color(named: "AliasInteractionNormMinor2")

    static var cardInteractionNorm = Self.color(named: "CardInteractionNorm")
    static var cardInteractionNormMajor1 = Self.color(named: "CardInteractionNormMajor1")
    static var cardInteractionNormMajor2 = Self.color(named: "CardInteractionNormMajor2")
    static var cardInteractionNormMinor1 = Self.color(named: "CardInteractionNormMinor1")
    static var cardInteractionNormMinor2 = Self.color(named: "CardInteractionNormMinor2")

    static var loginInteractionNorm = Self.color(named: "LoginInteractionNorm")
    static var loginInteractionNormMajor1 = Self.color(named: "LoginInteractionNormMajor1")
    static var loginInteractionNormMajor2 = Self.color(named: "LoginInteractionNormMajor2")
    static var loginInteractionNormMinor1 = Self.color(named: "LoginInteractionNormMinor1")
    static var loginInteractionNormMinor2 = Self.color(named: "LoginInteractionNormMinor2")

    static var noteInteractionNorm = Self.color(named: "NoteInteractionNorm")
    static var noteInteractionNormMajor1 = Self.color(named: "NoteInteractionNormMajor1")
    static var noteInteractionNormMajor2 = Self.color(named: "NoteInteractionNormMajor2")
    static var noteInteractionNormMinor1 = Self.color(named: "NoteInteractionNormMinor1")
    static var noteInteractionNormMinor2 = Self.color(named: "NoteInteractionNormMinor2")

    static var passwordInteractionNorm = Self.color(named: "PasswordInteractionNorm")
    static var passwordInteractionNormMajor1 = Self.color(named: "PasswordInteractionNormMajor1")
    static var passwordInteractionNormMajor2 = Self.color(named: "PasswordInteractionNormMajor2")
    static var passwordInteractionNormMinor1 = Self.color(named: "PasswordInteractionNormMinor1")
    static var passwordInteractionNormMinor2 = Self.color(named: "PasswordInteractionNormMinor2")
}

// MARK: - Signals

public extension PassColor {
    static var signalDanger = Self.color(named: "SignalDanger")
    static var signalInfo = Self.color(named: "SignalInfo")
    static var signalSuccess = Self.color(named: "SignalSuccess")
    static var signalWarning = Self.color(named: "SignalWarning")
}

// MARK: - Texts

public extension PassColor {
    static var textDisabled = Self.color(named: "TextDisabled")
    static var textHint = Self.color(named: "TextHint")
    static var textInvert = Self.color(named: "TextInvert")
    static var textNorm = Self.color(named: "TextNorm")
    static var textWeak = Self.color(named: "TextWeak")
}

// MARK: - Vaults

public extension PassColor {
    static var vaultChestnutRose = Self.color(named: "VaultChestnutRose")
    static var vaultDeYork = Self.color(named: "VaultDeYork")
    static var vaultHeliotrope = Self.color(named: "VaultHeliotrope")
    static var vaultJordyBlue = Self.color(named: "VaultJordyBlue")
    static var vaultLavenderMagenta = Self.color(named: "VaultLavenderMagenta")
    static var vaultMarigoldYellow = Self.color(named: "VaultMarigoldYellow")
    static var vaultMauvelous = Self.color(named: "VaultMauvelous")
    static var vaultMercury = Self.color(named: "VaultMercury")
    static var vaultPorsche = Self.color(named: "VaultPorsche")
    static var vaultWaterLeaf = Self.color(named: "VaultWaterLeaf")
}

// swiftlint:enable force_unwrapping
