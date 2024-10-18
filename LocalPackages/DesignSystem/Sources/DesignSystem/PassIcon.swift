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

public enum PassIcon: Sendable {}

private extension PassIcon {
    static func icon(named: String) -> UIImage {
        UIImage(named: named, in: .module, with: nil)!
    }
}

public extension PassIcon {
    static let autoFillOnWebPreview = Self.icon(named: "AutoFillOnWebPreview")
    static let enableAutoFillStep2a = Self.icon(named: "EnableAutoFillStep2a")
    static let enableAutoFillStep2b = Self.icon(named: "EnableAutoFillStep2b")

    static let badgePaid = Self.icon(named: "BadgePaid")
    static let badgeTrial = Self.icon(named: "BadgeTrial")

    static let brandPass = Self.icon(named: "BrandPass")
    static let brandReddit = Self.icon(named: "BrandReddit")
    static let brandTwitter = Self.icon(named: "BrandTwitter")
    static let magnifyingGlass = Self.icon(named: "MagnifyingGlass")

    static let coverScreenBackground = Self.icon(named: "CoverScreenBackground")
    static let coverScreenLogo = Self.icon(named: "CoverScreenLogo")
    static let extraPassword = Self.icon(named: "ExtraPassword")

    static let filterFilled = Self.icon(named: "FilterFilled")
    static let infoBannerAliases = Self.icon(named: "InfoBannerAliases")
    static let infoBannerAutoFill = Self.icon(named: "InfoBannerAutoFill")
    static let infoBannerPass = Self.icon(named: "InfoBannerPass")
    static let slSyncIcon = Self.icon(named: "SlSyncIcon")

    static let inviteBannerIcon = Self.icon(named: "InviteBannerIcon")
    static let passPlus = Self.icon(named: "PassPlus")
    static let shield2 = Self.icon(named: "Shield2")
    static let passSubscriptionBadge = Self.icon(named: "PassSubscriptionBadge")
    static let passSubscriptionUnlimited = Self.icon(named: "PassSubscriptionUnlimited")
    static let lightning = Self.icon(named: "Lightning")
    static let breachShieldResolved = Self.icon(named: "BreachShieldResolved")
    static let breachShieldUnresolved = Self.icon(named: "BreachShieldUnresolved")
    static let securityEmptyState = Self.icon(named: "SecurityEmptyState")
    static let stamp = Self.icon(named: "Stamp")
    static let envelope = Self.icon(named: "Envelope")
    static let halfButtons = Self.icon(named: "HalfButtons")

    static let netShield = Self.icon(named: "Netshield")
    static let sentinelLogo = Self.icon(named: "SentinelLogo")

    static let onboardAliases = Self.icon(named: "OnboardAliases")
    static let onboardAuthentication = Self.icon(named: "OnboardAuthentication")
    static let onboardAuthenticationBackground = Self.icon(named: "OnboardAuthenticationBackground")
    static let onboardAuthenticationEnabled = Self.icon(named: "OnboardAuthenticationEnabled")
    static let onboardAutoFillGradient = Self.icon(named: "OnboardAutoFillGradient")
    static let onboardAutoFillEnabled = Self.icon(named: "OnboardAutoFillEnabled")
    static let onboardAutoFillStep1 = Self.icon(named: "OnboardAutoFillStep1")
    static let onboardAutoFillStep2 = Self.icon(named: "OnboardAutoFillStep2")
    static let onboardAutoFillStep3 = Self.icon(named: "OnboardAutoFillStep3")
    static let onboardAutoFillStep4 = Self.icon(named: "OnboardAutoFillStep4")
    static let onboardAutoFillStep5 = Self.icon(named: "OnboardAutoFillStep5")

    static let passCreditCardOneStripe = Self.icon(named: "PassCreditCardOneStripe")
    static let passCreditCardTwoStripes = Self.icon(named: "PassCreditCardTwoStripes")
    static let passIcon = Self.icon(named: "PassIcon")
    static let passkey = Self.icon(named: "Passkey")
    static let passTextLogo = Self.icon(named: "PassTextLogo")
    static let pinAngled = Self.icon(named: "PinAngled")
    static let pinAngledFilled = Self.icon(named: "PinAngledFilled")
    static let pinAngledSlash = Self.icon(named: "PinAngledSlash")
    static let scanner = Self.icon(named: "Scanner")
    static let shieldCheck = Self.icon(named: "ShieldCheck")
    static let swirls = Self.icon(named: "Swirls")
    static let aliasSlash = Self.icon(named: "AliasSlash")

    static let tabProfilePaidSelected = Self.icon(named: "TabProfilePaidSelected")
    static let tabProfilePaidUnselected = Self.icon(named: "TabProfilePaidUnselected")
    static let tabProfileTrialSelected = Self.icon(named: "TabProfileTrialSelected")
    static let tabProfileTrialUnselected = Self.icon(named: "TabProfileTrialUnselected")
    static let tabAuthenticator = Self.icon(named: "TabAuthenticator")

    // swiftlint:disable identifier_name
    static let tabMonitorActiveBreachesFoundSelected = Self.icon(named: "TabMonitorActiveBreachesFoundSelected")
    static let tabMonitorActiveBreachesFoundUnselected =
        Self.icon(named: "TabMonitorActiveBreachesFoundUnselected")
    static let tabMonitorActiveNoBreachesSelected = Self.icon(named: "TabMonitorActiveNoBreachesSelected")
    static let tabMonitorActiveNoBreachesUnselected = Self.icon(named: "TabMonitorActiveNoBreachesUnselected")
    static let tabMonitorActiveNoBreachesWeakReusedPasswordsSelected =
        Self.icon(named: "TabMonitorActiveNoBreachesWeakReusedPasswordsSelected")
    static let tabMonitorActiveNoBreachesWeakReusedPasswordsUnselected =
        Self.icon(named: "TabMonitorActiveNoBreachesWeakReusedPasswordsUnselected")
    static let tabMonitorInactiveBreachesFoundSelected =
        Self.icon(named: "TabMonitorInactiveBreachesFoundSelected")
    static let tabMonitorInactiveBreachesFoundUnselected = Self
        .icon(named: "TabMonitorInactiveBreachesFoundUnselected")
    static let tabMonitorInactiveNoBreachesSelected = Self.icon(named: "TabMonitorInactiveNoBreachesSelected")
    static let tabMonitorInactiveNoBreachesUnselected = Self.icon(named: "TabMonitorInactiveNoBreachesUnselected")
    static let tabMonitorInactiveNoBreachesWeakReusedPasswordsSelected =
        Self.icon(named: "TabMonitorInactiveNoBreachesWeakReusedPasswordsSelected")
    static let tabMonitorInactiveNoBreachesWeakReusedPasswordsUnselected =
        Self.icon(named: "TabMonitorInactiveNoBreachesWeakReusedPasswordsUnselected")
    // swiftlint:enable identifier_name

    static let trash = Self.icon(named: "Trash")

    static let trial2FA = Self.icon(named: "Trial2FA")
    static let trialCustomFields = Self.icon(named: "TrialCustomFields")
    static let trialDetail = Self.icon(named: "TrialDetail")
    static let trialVaults = Self.icon(named: "TrialVaults")
    static let youtube = Self.icon(named: "Youtube")

    static let vaultIcon1Big = Self.icon(named: "VaultIcon1Big")
    static let vaultIcon1Small = Self.icon(named: "VaultIcon1Small")
    static let vaultIcon2Big = Self.icon(named: "VaultIcon2Big")
    static let vaultIcon2Small = Self.icon(named: "VaultIcon2Small")
    static let vaultIcon3Big = Self.icon(named: "VaultIcon3Big")
    static let vaultIcon3Small = Self.icon(named: "VaultIcon3Small")
    static let vaultIcon4Big = Self.icon(named: "VaultIcon4Big")
    static let vaultIcon4Small = Self.icon(named: "VaultIcon4Small")
    static let vaultIcon5Big = Self.icon(named: "VaultIcon5Big")
    static let vaultIcon5Small = Self.icon(named: "VaultIcon5Small")
    static let vaultIcon6Big = Self.icon(named: "VaultIcon6Big")
    static let vaultIcon6Small = Self.icon(named: "VaultIcon6Small")
    static let vaultIcon7Big = Self.icon(named: "VaultIcon7Big")
    static let vaultIcon7Small = Self.icon(named: "VaultIcon7Small")
    static let vaultIcon8Big = Self.icon(named: "VaultIcon8Big")
    static let vaultIcon8Small = Self.icon(named: "VaultIcon8Small")
    static let vaultIcon9Big = Self.icon(named: "VaultIcon9Big")
    static let vaultIcon9Small = Self.icon(named: "VaultIcon9Small")
    static let vaultIcon10Big = Self.icon(named: "VaultIcon10Big")
    static let vaultIcon10Small = Self.icon(named: "VaultIcon10Small")
    static let vaultIcon11Big = Self.icon(named: "VaultIcon11Big")
    static let vaultIcon11Small = Self.icon(named: "VaultIcon11Small")
    static let vaultIcon12Big = Self.icon(named: "VaultIcon12Big")
    static let vaultIcon12Small = Self.icon(named: "VaultIcon12Small")
    static let vaultIcon13Big = Self.icon(named: "VaultIcon13Big")
    static let vaultIcon13Small = Self.icon(named: "VaultIcon13Small")
    static let vaultIcon14Big = Self.icon(named: "VaultIcon14Big")
    static let vaultIcon14Small = Self.icon(named: "VaultIcon14Small")
    static let vaultIcon15Big = Self.icon(named: "VaultIcon15Big")
    static let vaultIcon15Small = Self.icon(named: "VaultIcon15Small")
    static let vaultIcon16Big = Self.icon(named: "VaultIcon16Big")
    static let vaultIcon16Small = Self.icon(named: "VaultIcon16Small")
    static let vaultIcon17Big = Self.icon(named: "VaultIcon17Big")
    static let vaultIcon17Small = Self.icon(named: "VaultIcon17Small")
    static let vaultIcon18Big = Self.icon(named: "VaultIcon18Big")
    static let vaultIcon18Small = Self.icon(named: "VaultIcon18Small")
    static let vaultIcon19Big = Self.icon(named: "VaultIcon19Big")
    static let vaultIcon19Small = Self.icon(named: "VaultIcon19Small")
    static let vaultIcon20Big = Self.icon(named: "VaultIcon20Big")
    static let vaultIcon20Small = Self.icon(named: "VaultIcon20Small")
    static let vaultIcon21Big = Self.icon(named: "VaultIcon21Big")
    static let vaultIcon21Small = Self.icon(named: "VaultIcon21Small")
    static let vaultIcon22Big = Self.icon(named: "VaultIcon22Big")
    static let vaultIcon22Small = Self.icon(named: "VaultIcon22Small")
    static let vaultIcon23Big = Self.icon(named: "VaultIcon23Big")
    static let vaultIcon23Small = Self.icon(named: "VaultIcon23Small")
    static let vaultIcon24Big = Self.icon(named: "VaultIcon24Big")
    static let vaultIcon24Small = Self.icon(named: "VaultIcon24Small")
    static let vaultIcon25Big = Self.icon(named: "VaultIcon25Big")
    static let vaultIcon25Small = Self.icon(named: "VaultIcon25Small")
    static let vaultIcon26Big = Self.icon(named: "VaultIcon26Big")
    static let vaultIcon26Small = Self.icon(named: "VaultIcon26Small")
    static let vaultIcon27Big = Self.icon(named: "VaultIcon27Big")
    static let vaultIcon27Small = Self.icon(named: "VaultIcon27Small")
    static let vaultIcon28Big = Self.icon(named: "VaultIcon28Big")
    static let vaultIcon28Small = Self.icon(named: "VaultIcon28Small")
    static let vaultIcon29Big = Self.icon(named: "VaultIcon29Big")
    static let vaultIcon29Small = Self.icon(named: "VaultIcon29Small")
    static let vaultIcon30Big = Self.icon(named: "VaultIcon30Big")
    static let vaultIcon30Small = Self.icon(named: "VaultIcon30Small")
}

// swiftlint:enable force_unwrapping
