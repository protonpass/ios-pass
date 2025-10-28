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

import SwiftUI

public enum PassIcon: Sendable {}

public extension PassIcon {
    static let aliasSync = Image(.aliasSync)
    static let autoFillOnWebPreview = Image(.autoFillOnWebPreview)
    static let enableAutoFillStep2a = Image(.enableAutoFillStep2A)
    static let enableAutoFillStep2b = Image(.enableAutoFillStep2B)

    static let badgePaid = Image(.badgePaid)
    static let badgeTrial = Image(.badgeTrial)

    static let brandPass = Image(.brandPass)
    static let brandReddit = Image(.brandReddit)
    static let brandTwitter = Image(.brandTwitter)
    static let magnifyingGlass = Image(.magnifyingGlass)

    static let clearHistory = Image(.clearHistory)
    static let coverScreenLogo = Image(.coverScreenLogo)
    static let extraPassword = Image(.extraPassword)

    static let fileAttachments = Image(.fileAttachments)
    static let documentScan = Image(.documentScan)
    static let images = Image(.images)
    static let rename = Image(.rename)
    static let storageFull = Image(.storageFull)

    static let fileTypeImage = Image(.fileType)
    static let fileTypePhoto = Image(.fileTypePhoto)
    static let fileTypeVectorImage = Image(.fileTypeVector)
    static let fileTypeVideo = Image(.fileTypeVideo)
    static let fileTypeAudio = Image(.fileTypeAudio)
    static let fileTypeKey = Image(.fileTypeKey)
    static let fileTypeText = Image(.fileTypeText)
    static let fileTypeCalendar = Image(.fileTypeCalendar)
    static let fileTypePdf = Image(.fileTypePdf)
    static let fileTypeWord = Image(.fileTypeWord)
    static let fileTypePowerPoint = Image(.fileTypePowerpoint)
    static let fileTypeExcel = Image(.fileTypeExcel)
    static let fileTypeDocument = Image(.fileTypeDocument)
    static let fileTypeUnknown = Image(.fileTypeUnknown)

    static let filterFilled = Image(.filterFilled)
    static let hamburgerPlus = Image(.hamburgerPlus)
    static let infoBannerAliases = Image(.infoBannerAliases)
    static let infoBannerAutoFill = Image(.infoBannerAutoFill)
    static let infoBannerPass = Image(.infoBannerPass)
    static let slSyncIcon = Image(.slSyncIcon)

    static let inviteBannerIcon = Image(.inviteBannerIcon)
    static let passPlus = Image(.passPlus)
    static let shield2 = Image(.shield2)
    static let passSubscriptionBadge = Image(.passSubscriptionBadge)
    static let passSubscriptionUnlimited = Image(.passSubscriptionUnlimited)
    static let lightning = Image(.lightning)
    static let breachShieldResolved = Image(.breachShieldResolved)
    static let breachShieldUnresolved = Image(.breachShieldUnresolved)
    static let securityEmptyState = Image(.securityEmptyState)
    static let stamp = Image(.stamp)
    static let envelope = Image(.envelope)
    static let halfButtons = Image(.halfButtons)

    static let netShield = Image(.netshield)
    static let sentinelLogo = Image(.sentinelLogo)

    static let onboardAliasExplanation = Image(.onboardAliasExplanation)
    static let onboardAutoFill = Image(.onboardAutoFill)
    static let onboardFaceID = Image(.onboardFaceID)
    static let onboardLoginCreatedSparkle = Image(.onboardLoginCreatedSparkle)

    static let firstLoginScreen = Image(.firstLoginScreen)
    static let secondLoginScreen = Image(.secondLoginScreen)
    static let thirdLoginScreen = Image(.thirdLoginScreen)
    static let fourthLoginScreen = Image(.fourthLoginScreen)
    static let loginDeviceIcons = Image(.deviceIcons)

    static let passCreditCardOneStripe = Image(.passCreditCardOneStripe)
    static let passCreditCardTwoStripes = Image(.passCreditCardTwoStripes)
    static let passIcon = Image(.passIcon)
    static let passkey = Image(.passkey)
    static let passTextLogo = Image(.passTextLogo)
    static let penSparks = Image(.penSparks)
    static let pinAngled = Image(.pinAngled)
    static let pinAngledFilled = Image(.pinAngledFilled)
    static let pinAngledSlash = Image(.pinAngledSlash)
    static let promoBadge = Image(.promoBadge)
    static let protonStamp = Image(.protonStamp)
    static let scanner = Image(.scanner)
    static let shieldCheck = Image(.shieldCheck)
    static let shieldLock = Image(.shieldLock)
    static let aliasSlash = Image(.aliasSlash)
    static let bank = Image(.bank)
    static let brandBitcoin = Image(.brandBitcoin)

    static let tabProfilePaidSelected = UIImage.tabProfilePaidSelected
    static let tabProfilePaidUnselected = UIImage.tabProfilePaidUnselected
    static let tabProfileTrialSelected = UIImage.tabProfileTrialSelected
    static let tabProfileTrialUnselected = UIImage.tabProfileTrialUnselected

    // swiftlint:disable identifier_name
    static let tabMonitorActiveBreachesFoundSelected = UIImage.tabMonitorActiveBreachesFoundSelected
    static let tabMonitorActiveBreachesFoundUnselected =
        UIImage.tabMonitorActiveBreachesFoundUnselected
    static let tabMonitorActiveNoBreachesSelected = UIImage.tabMonitorActiveNoBreachesSelected
    static let tabMonitorActiveNoBreachesUnselected = UIImage.tabMonitorActiveNoBreachesUnselected
    static let tabMonitorActiveNoBreachesWeakReusedPasswordsSelected =
        UIImage.tabMonitorActiveNoBreachesWeakReusedPasswordsSelected
    static let tabMonitorActiveNoBreachesWeakReusedPasswordsUnselected =
        UIImage.tabMonitorActiveNoBreachesWeakReusedPasswordsUnselected
    static let tabMonitorInactiveBreachesFoundSelected =
        UIImage.tabMonitorInactiveBreachesFoundSelected
    static let tabMonitorInactiveBreachesFoundUnselected = UIImage.tabMonitorInactiveBreachesFoundUnselected
    static let tabMonitorInactiveNoBreachesSelected = UIImage.tabMonitorInactiveNoBreachesSelected
    static let tabMonitorInactiveNoBreachesUnselected = UIImage.tabMonitorInactiveNoBreachesUnselected
    static let tabMonitorInactiveNoBreachesWeakReusedPasswordsSelected =
        UIImage.tabMonitorInactiveNoBreachesWeakReusedPasswordsSelected
    static let tabMonitorInactiveNoBreachesWeakReusedPasswordsUnselected =
        UIImage.tabMonitorInactiveNoBreachesWeakReusedPasswordsUnselected
    // swiftlint:enable identifier_name

    static let trash = Image(.trash)

    static let trial2FA = Image(.trial2FA)
    static let trialCustomFields = Image(.trialCustomFields)
    static let trialDetail = Image(.trialDetail)
    static let trialVaults = Image(.trialVaults)
    static let youtube = Image(.youtube)
    static let diamond = Image(.diamond)

    static let vaultIcon1Big = Image(.vaultIcon1Big)
    static let vaultIcon1Small = Image(.vaultIcon1Small)
    static let vaultIcon2Big = Image(.vaultIcon2Big)
    static let vaultIcon2Small = Image(.vaultIcon2Small)
    static let vaultIcon3Big = Image(.vaultIcon3Big)
    static let vaultIcon3Small = Image(.vaultIcon3Small)
    static let vaultIcon4Big = Image(.vaultIcon4Big)
    static let vaultIcon4Small = Image(.vaultIcon4Small)
    static let vaultIcon5Big = Image(.vaultIcon5Big)
    static let vaultIcon5Small = Image(.vaultIcon5Small)
    static let vaultIcon6Big = Image(.vaultIcon6Big)
    static let vaultIcon6Small = Image(.vaultIcon6Small)
    static let vaultIcon7Big = Image(.vaultIcon7Big)
    static let vaultIcon7Small = Image(.vaultIcon7Small)
    static let vaultIcon8Big = Image(.vaultIcon8Big)
    static let vaultIcon8Small = Image(.vaultIcon8Small)
    static let vaultIcon9Big = Image(.vaultIcon9Big)
    static let vaultIcon9Small = Image(.vaultIcon9Small)
    static let vaultIcon10Big = Image(.vaultIcon10Big)
    static let vaultIcon10Small = Image(.vaultIcon10Small)
    static let vaultIcon11Big = Image(.vaultIcon11Big)
    static let vaultIcon11Small = Image(.vaultIcon11Small)
    static let vaultIcon12Big = Image(.vaultIcon12Big)
    static let vaultIcon12Small = Image(.vaultIcon12Small)
    static let vaultIcon13Big = Image(.vaultIcon13Big)
    static let vaultIcon13Small = Image(.vaultIcon13Small)
    static let vaultIcon14Big = Image(.vaultIcon14Big)
    static let vaultIcon14Small = Image(.vaultIcon14Small)
    static let vaultIcon15Big = Image(.vaultIcon15Big)
    static let vaultIcon15Small = Image(.vaultIcon15Small)
    static let vaultIcon16Big = Image(.vaultIcon16Big)
    static let vaultIcon16Small = Image(.vaultIcon16Small)
    static let vaultIcon17Big = Image(.vaultIcon17Big)
    static let vaultIcon17Small = Image(.vaultIcon17Small)
    static let vaultIcon18Big = Image(.vaultIcon18Big)
    static let vaultIcon18Small = Image(.vaultIcon18Small)
    static let vaultIcon19Big = Image(.vaultIcon19Big)
    static let vaultIcon19Small = Image(.vaultIcon19Small)
    static let vaultIcon20Big = Image(.vaultIcon20Big)
    static let vaultIcon20Small = Image(.vaultIcon20Small)
    static let vaultIcon21Big = Image(.vaultIcon21Big)
    static let vaultIcon21Small = Image(.vaultIcon21Small)
    static let vaultIcon22Big = Image(.vaultIcon22Big)
    static let vaultIcon22Small = Image(.vaultIcon22Small)
    static let vaultIcon23Big = Image(.vaultIcon23Big)
    static let vaultIcon23Small = Image(.vaultIcon23Small)
    static let vaultIcon24Big = Image(.vaultIcon24Big)
    static let vaultIcon24Small = Image(.vaultIcon24Small)
    static let vaultIcon25Big = Image(.vaultIcon25Big)
    static let vaultIcon25Small = Image(.vaultIcon25Small)
    static let vaultIcon26Big = Image(.vaultIcon26Big)
    static let vaultIcon26Small = Image(.vaultIcon26Small)
    static let vaultIcon27Big = Image(.vaultIcon27Big)
    static let vaultIcon27Small = Image(.vaultIcon27Small)
    static let vaultIcon28Big = Image(.vaultIcon28Big)
    static let vaultIcon28Small = Image(.vaultIcon28Small)
    static let vaultIcon29Big = Image(.vaultIcon29Big)
    static let vaultIcon29Small = Image(.vaultIcon29Small)
    static let vaultIcon30Big = Image(.vaultIcon30Big)
    static let vaultIcon30Small = Image(.vaultIcon30Small)
}
