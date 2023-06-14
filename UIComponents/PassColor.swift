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

public extension PassColor {
    static var inputBackgroundNorm = UIColor(named: "InputBackgroundNorm")!
    static var inputBorderNorm = UIColor(named: "InputBorderNorm")!

    static var interactionNorm = UIColor(named: "InteractionNorm")!
    static var interactionNormMajor1 = UIColor(named: "InteractionNormMajor1")!
    static var interactionNormMajor2 = UIColor(named: "InteractionNormMajor2")!
    static var interactionNormMinor1 = UIColor(named: "InteractionNormMinor1")!
    static var interactionNormMinor2 = UIColor(named: "InteractionNormMinor2")!
}

// MARK: - Background
public extension PassColor {
    static var backdrop = UIColor(named: "Backdrop")
    static var backgroundMedium = UIColor(named: "BackgroundMedium")!
    static var backgroundNorm = UIColor(named: "BackgroundNorm")!
    static var backgroundStrong = UIColor(named: "BackgroundStrong")!
    static var backgroundWeak = UIColor(named: "BackgroundWeak")!
    static var tabBarBackground = UIColor(named: "TabBarBackground")!
}

// MARK: - Items
public extension PassColor {
    static var aliasInteractionNorm = UIColor(named: "AliasInteractionNorm")!
    static var aliasInteractionNormMajor1 = UIColor(named: "AliasInteractionNormMajor1")!
    static var aliasInteractionNormMajor2 = UIColor(named: "AliasInteractionNormMajor2")!
    static var aliasInteractionNormMinor1 = UIColor(named: "AliasInteractionNormMinor1")!
    static var aliasInteractionNormMinor2 = UIColor(named: "AliasInteractionNormMinor2")!

    static var cardInteractionNorm = UIColor(named: "CardInteractionNorm")!
    static var cardInteractionNormMajor1 = UIColor(named: "CardInteractionNormMajor1")!
    static var cardInteractionNormMajor2 = UIColor(named: "CardInteractionNormMajor2")!
    static var cardInteractionNormMinor1 = UIColor(named: "CardInteractionNormMinor1")!
    static var cardInteractionNormMinor2 = UIColor(named: "CardInteractionNormMinor2")!

    static var loginInteractionNorm = UIColor(named: "LoginInteractionNorm")!
    static var loginInteractionNormMajor1 = UIColor(named: "LoginInteractionNormMajor1")!
    static var loginInteractionNormMajor2 = UIColor(named: "LoginInteractionNormMajor2")!
    static var loginInteractionNormMinor1 = UIColor(named: "LoginInteractionNormMinor1")!
    static var loginInteractionNormMinor2 = UIColor(named: "LoginInteractionNormMinor2")!

    static var noteInteractionNorm = UIColor(named: "NoteInteractionNorm")!
    static var noteInteractionNormMajor1 = UIColor(named: "NoteInteractionNormMajor1")!
    static var noteInteractionNormMajor2 = UIColor(named: "NoteInteractionNormMajor2")!
    static var noteInteractionNormMinor1 = UIColor(named: "NoteInteractionNormMinor1")!
    static var noteInteractionNormMinor2 = UIColor(named: "NoteInteractionNormMinor2")!

    static var passwordInteractionNorm = UIColor(named: "PasswordInteractionNorm")!
    static var passwordInteractionNormMajor1 = UIColor(named: "PasswordInteractionNormMajor1")!
    static var passwordInteractionNormMajor2 = UIColor(named: "PasswordInteractionNormMajor2")!
    static var passwordInteractionNormMinor1 = UIColor(named: "PasswordInteractionNormMinor1")!
    static var passwordInteractionNormMinor2 = UIColor(named: "PasswordInteractionNormMinor2")!
}

// MARK: - Signals
public extension PassColor {
    static var signalDanger = UIColor(named: "SignalDanger")!
    static var signalInfo = UIColor(named: "SignalInfo")!
    static var signalSuccess = UIColor(named: "SignalSuccess")!
    static var signalWarning = UIColor(named: "SignalWarning")!
}

// MARK: - Texts
public extension PassColor {
    static var textDisabled = UIColor(named: "TextDisabled")!
    static var textHint = UIColor(named: "TextHint")!
    static var textInvert = UIColor(named: "TextInvert")!
    static var textNorm = UIColor(named: "TextNorm")!
    static var textWeak = UIColor(named: "TextWeak")!
}

// MARK: - Vaults
public extension PassColor {
    static var vaultChestnutRose = UIColor(named: "VaultChestnutRose")!
    static var vaultDeYork = UIColor(named: "VaultDeYork")!
    static var vaultHeliotrope = UIColor(named: "VaultHeliotrope")!
    static var vaultJordyBlue = UIColor(named: "VaultJordyBlue")!
    static var vaultLavenderMagenta = UIColor(named: "VaultLavenderMagenta")!
    static var vaultMarigoldYellow = UIColor(named: "VaultMarigoldYellow")!
    static var vaultMauvelous = UIColor(named: "VaultMauvelous")!
    static var vaultMercury = UIColor(named: "VaultMercury")!
    static var vaultPorsche = UIColor(named: "VaultPorsche")!
    static var vaultWaterLeaf = UIColor(named: "VaultWaterLeaf")!
}
// swiftlint:enable force_unwrapping
