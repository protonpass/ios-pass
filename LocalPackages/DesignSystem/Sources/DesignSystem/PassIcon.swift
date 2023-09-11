//
// PassIcon.swift
// Proton Pass - Created on 13/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public enum PassIcon {}

private extension PassIcon {
    static func icon(named: String) -> UIImage {
        UIImage(named: named, in: .module, with: nil)!
    }
}

public extension PassIcon {
    static var autoFillOnWebPreview = Self.icon(named: "AutoFillOnWebPreview")
    static var enableAutoFillStep2a = Self.icon(named: "EnableAutoFillStep2a")
    static var enableAutoFillStep2b = Self.icon(named: "EnableAutoFillStep2b")

    static var badgePaid = Self.icon(named: "BadgePaid")
    static var badgeTrial = Self.icon(named: "BadgeTrial")

    static var brandPass = Self.icon(named: "BrandPass")
    static var brandReddit = Self.icon(named: "BrandReddit")
    static var brandTwitter = Self.icon(named: "BrandTwitter")
    static var magnifyingGlass = Self.icon(named: "MagnifyingGlass")

    static var coverScreenBackground = Self.icon(named: "CoverScreenBackground")
    static var coverScreenLogo = Self.icon(named: "CoverScreenLogo")

    static var infoBannerAliases = Self.icon(named: "InfoBannerAliases")
    static var infoBannerAutoFill = Self.icon(named: "InfoBannerAutoFill")
    static var infoBannerPass = Self.icon(named: "InfoBannerPass")

    static var inviteBannerIcon = Self.icon(named: "InviteBannerIcon")

    static var onboardAliases = Self.icon(named: "OnboardAliases")
    static var onboardAuthentication = Self.icon(named: "OnboardAuthentication")
    static var onboardAuthenticationBackground = Self.icon(named: "OnboardAuthenticationBackground")
    static var onboardAuthenticationEnabled = Self.icon(named: "OnboardAuthenticationEnabled")
    static var onboardAutoFillGradient = Self.icon(named: "OnboardAutoFillGradient")
    static var onboardAutoFillEnabled = Self.icon(named: "OnboardAutoFillEnabled")
    static var onboardAutoFillStep1 = Self.icon(named: "OnboardAutoFillStep1")
    static var onboardAutoFillStep2 = Self.icon(named: "OnboardAutoFillStep2")
    static var onboardAutoFillStep3 = Self.icon(named: "OnboardAutoFillStep3")
    static var onboardAutoFillStep4 = Self.icon(named: "OnboardAutoFillStep4")
    static var onboardAutoFillStep5 = Self.icon(named: "OnboardAutoFillStep5")

    static var passCreditCardOneStripe = Self.icon(named: "PassCreditCardOneStripe")
    static var passCreditCardTwoStripes = Self.icon(named: "PassCreditCardTwoStripes")
    static var passIcon = Self.icon(named: "PassIcon")
    static var passTextLogo = Self.icon(named: "PassTextLogo")
    static var scanner = Self.icon(named: "Scanner")
    static var shieldCheck = Self.icon(named: "ShieldCheck")
    static var swirls = Self.icon(named: "Swirls")

    static var tabProfilePaidSelected = Self.icon(named: "TabProfilePaidSelected")
    static var tabProfilePaidUnselected = Self.icon(named: "TabProfilePaidUnselected")
    static var tabProfileTrialSelected = Self.icon(named: "TabProfileTrialSelected")
    static var tabProfileTrialUnselected = Self.icon(named: "TabProfileTrialUnselected")

    static var trash = Self.icon(named: "Trash")

    static var trial2FA = Self.icon(named: "Trial2FA")
    static var trialCustomFields = Self.icon(named: "TrialCustomFields")
    static var trialDetail = Self.icon(named: "TrialDetail")
    static var trialVaults = Self.icon(named: "TrialVaults")

    static var vaultIcon1Big = Self.icon(named: "VaultIcon1Big")
    static var vaultIcon1Small = Self.icon(named: "VaultIcon1Small")
    static var vaultIcon2Big = Self.icon(named: "VaultIcon2Big")
    static var vaultIcon2Small = Self.icon(named: "VaultIcon2Small")
    static var vaultIcon3Big = Self.icon(named: "VaultIcon3Big")
    static var vaultIcon3Small = Self.icon(named: "VaultIcon3Small")
    static var vaultIcon4Big = Self.icon(named: "VaultIcon4Big")
    static var vaultIcon4Small = Self.icon(named: "VaultIcon4Small")
    static var vaultIcon5Big = Self.icon(named: "VaultIcon5Big")
    static var vaultIcon5Small = Self.icon(named: "VaultIcon5Small")
    static var vaultIcon6Big = Self.icon(named: "VaultIcon6Big")
    static var vaultIcon6Small = Self.icon(named: "VaultIcon6Small")
    static var vaultIcon7Big = Self.icon(named: "VaultIcon7Big")
    static var vaultIcon7Small = Self.icon(named: "VaultIcon7Small")
    static var vaultIcon8Big = Self.icon(named: "VaultIcon8Big")
    static var vaultIcon8Small = Self.icon(named: "VaultIcon8Small")
    static var vaultIcon9Big = Self.icon(named: "VaultIcon9Big")
    static var vaultIcon9Small = Self.icon(named: "VaultIcon9Small")
    static var vaultIcon10Big = Self.icon(named: "VaultIcon10Big")
    static var vaultIcon10Small = Self.icon(named: "VaultIcon10Small")
    static var vaultIcon11Big = Self.icon(named: "VaultIcon11Big")
    static var vaultIcon11Small = Self.icon(named: "VaultIcon11Small")
    static var vaultIcon12Big = Self.icon(named: "VaultIcon12Big")
    static var vaultIcon12Small = Self.icon(named: "VaultIcon12Small")
    static var vaultIcon13Big = Self.icon(named: "VaultIcon13Big")
    static var vaultIcon13Small = Self.icon(named: "VaultIcon13Small")
    static var vaultIcon14Big = Self.icon(named: "VaultIcon14Big")
    static var vaultIcon14Small = Self.icon(named: "VaultIcon14Small")
    static var vaultIcon15Big = Self.icon(named: "VaultIcon15Big")
    static var vaultIcon15Small = Self.icon(named: "VaultIcon15Small")
    static var vaultIcon16Big = Self.icon(named: "VaultIcon16Big")
    static var vaultIcon16Small = Self.icon(named: "VaultIcon16Small")
    static var vaultIcon17Big = Self.icon(named: "VaultIcon17Big")
    static var vaultIcon17Small = Self.icon(named: "VaultIcon17Small")
    static var vaultIcon18Big = Self.icon(named: "VaultIcon18Big")
    static var vaultIcon18Small = Self.icon(named: "VaultIcon18Small")
    static var vaultIcon19Big = Self.icon(named: "VaultIcon19Big")
    static var vaultIcon19Small = Self.icon(named: "VaultIcon19Small")
    static var vaultIcon20Big = Self.icon(named: "VaultIcon20Big")
    static var vaultIcon20Small = Self.icon(named: "VaultIcon20Small")
    static var vaultIcon21Big = Self.icon(named: "VaultIcon21Big")
    static var vaultIcon21Small = Self.icon(named: "VaultIcon21Small")
    static var vaultIcon22Big = Self.icon(named: "VaultIcon22Big")
    static var vaultIcon22Small = Self.icon(named: "VaultIcon22Small")
    static var vaultIcon23Big = Self.icon(named: "VaultIcon23Big")
    static var vaultIcon23Small = Self.icon(named: "VaultIcon23Small")
    static var vaultIcon24Big = Self.icon(named: "VaultIcon24Big")
    static var vaultIcon24Small = Self.icon(named: "VaultIcon24Small")
    static var vaultIcon25Big = Self.icon(named: "VaultIcon25Big")
    static var vaultIcon25Small = Self.icon(named: "VaultIcon25Small")
    static var vaultIcon26Big = Self.icon(named: "VaultIcon26Big")
    static var vaultIcon26Small = Self.icon(named: "VaultIcon26Small")
    static var vaultIcon27Big = Self.icon(named: "VaultIcon27Big")
    static var vaultIcon27Small = Self.icon(named: "VaultIcon27Small")
    static var vaultIcon28Big = Self.icon(named: "VaultIcon28Big")
    static var vaultIcon28Small = Self.icon(named: "VaultIcon28Small")
    static var vaultIcon29Big = Self.icon(named: "VaultIcon29Big")
    static var vaultIcon29Small = Self.icon(named: "VaultIcon29Small")
    static var vaultIcon30Big = Self.icon(named: "VaultIcon30Big")
    static var vaultIcon30Small = Self.icon(named: "VaultIcon30Small")
}

// swiftlint:enable force_unwrapping
