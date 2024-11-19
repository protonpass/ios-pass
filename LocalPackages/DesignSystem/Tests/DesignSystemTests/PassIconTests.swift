//
// PassIconTests.swift
// Proton Pass - Created on 17/04/2023.
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

@testable import DesignSystem
import XCTest

final class PassIconTests: XCTestCase {
    func testGetIconss() {
        let expectation = expectation(description: "Should be able to get icons")

        _ = PassIcon.autoFillOnWebPreview
        _ = PassIcon.enableAutoFillStep2a
        _ = PassIcon.enableAutoFillStep2b

        _ = PassIcon.badgePaid
        _ = PassIcon.badgeTrial

        _ = PassIcon.brandPass
        _ = PassIcon.brandReddit
        _ = PassIcon.brandTwitter

        _ = PassIcon.coverScreenBackground
        _ = PassIcon.coverScreenLogo
        _ = PassIcon.extraPassword

        _ = PassIcon.fileAttachments
        _ = PassIcon.documentScan
        _ = PassIcon.images

        _ = PassIcon.filterFilled

        _ = PassIcon.infoBannerAliases
        _ = PassIcon.infoBannerAutoFill
        _ = PassIcon.infoBannerPass

        _ = PassIcon.magnifyingGlass

        _ = PassIcon.onboardAliases
        _ = PassIcon.onboardAuthentication
        _ = PassIcon.onboardAuthenticationBackground
        _ = PassIcon.onboardAuthenticationEnabled
        _ = PassIcon.onboardAutoFillGradient
        _ = PassIcon.onboardAutoFillEnabled
        _ = PassIcon.onboardAutoFillStep1
        _ = PassIcon.onboardAutoFillStep2
        _ = PassIcon.onboardAutoFillStep3
        _ = PassIcon.onboardAutoFillStep4
        _ = PassIcon.onboardAutoFillStep5

        _ = PassIcon.passCreditCardOneStripe
        _ = PassIcon.passCreditCardTwoStripes
        _ = PassIcon.passIcon
        _ = PassIcon.passkey
        _ = PassIcon.passTextLogo
        _ = PassIcon.pinAngled
        _ = PassIcon.pinAngledFilled
        _ = PassIcon.pinAngledSlash
        _ = PassIcon.scanner
        _ = PassIcon.shieldCheck
        _ = PassIcon.swirls

        _ = PassIcon.tabProfilePaidSelected
        _ = PassIcon.tabProfilePaidUnselected
        _ = PassIcon.tabProfileTrialSelected
        _ = PassIcon.tabProfileTrialUnselected

        _ = PassIcon.tabMonitorActiveBreachesFoundSelected
        _ = PassIcon.tabMonitorActiveBreachesFoundUnselected
        _ = PassIcon.tabMonitorActiveNoBreachesSelected
        _ = PassIcon.tabMonitorActiveNoBreachesUnselected
        _ = PassIcon.tabMonitorActiveNoBreachesWeakReusedPasswordsSelected
        _ = PassIcon.tabMonitorActiveNoBreachesWeakReusedPasswordsUnselected
        _ = PassIcon.tabMonitorInactiveBreachesFoundSelected
        _ = PassIcon.tabMonitorInactiveBreachesFoundUnselected
        _ = PassIcon.tabMonitorInactiveNoBreachesSelected
        _ = PassIcon.tabMonitorInactiveNoBreachesUnselected
        _ = PassIcon.tabMonitorInactiveNoBreachesWeakReusedPasswordsSelected
        _ = PassIcon.tabMonitorInactiveNoBreachesWeakReusedPasswordsUnselected

        _ = PassIcon.trash

        _ = PassIcon.trial2FA
        _ = PassIcon.trialCustomFields
        _ = PassIcon.trialDetail
        _ = PassIcon.trialVaults
        _ = PassIcon.youtube

        _ = PassIcon.vaultIcon1Big
        _ = PassIcon.vaultIcon1Small
        _ = PassIcon.vaultIcon2Big
        _ = PassIcon.vaultIcon2Small
        _ = PassIcon.vaultIcon3Big
        _ = PassIcon.vaultIcon3Small
        _ = PassIcon.vaultIcon4Big
        _ = PassIcon.vaultIcon4Small
        _ = PassIcon.vaultIcon5Big
        _ = PassIcon.vaultIcon5Small
        _ = PassIcon.vaultIcon6Big
        _ = PassIcon.vaultIcon6Small
        _ = PassIcon.vaultIcon7Big
        _ = PassIcon.vaultIcon7Small
        _ = PassIcon.vaultIcon8Big
        _ = PassIcon.vaultIcon8Small
        _ = PassIcon.vaultIcon9Big
        _ = PassIcon.vaultIcon9Small
        _ = PassIcon.vaultIcon10Big
        _ = PassIcon.vaultIcon10Small
        _ = PassIcon.vaultIcon11Big
        _ = PassIcon.vaultIcon11Small
        _ = PassIcon.vaultIcon12Big
        _ = PassIcon.vaultIcon12Small
        _ = PassIcon.vaultIcon13Big
        _ = PassIcon.vaultIcon13Small
        _ = PassIcon.vaultIcon14Big
        _ = PassIcon.vaultIcon14Small
        _ = PassIcon.vaultIcon15Big
        _ = PassIcon.vaultIcon15Small
        _ = PassIcon.vaultIcon16Big
        _ = PassIcon.vaultIcon16Small
        _ = PassIcon.vaultIcon17Big
        _ = PassIcon.vaultIcon17Small
        _ = PassIcon.vaultIcon18Big
        _ = PassIcon.vaultIcon18Small
        _ = PassIcon.vaultIcon19Big
        _ = PassIcon.vaultIcon19Small
        _ = PassIcon.vaultIcon20Big
        _ = PassIcon.vaultIcon20Small
        _ = PassIcon.vaultIcon21Big
        _ = PassIcon.vaultIcon21Small
        _ = PassIcon.vaultIcon22Big
        _ = PassIcon.vaultIcon22Small
        _ = PassIcon.vaultIcon23Big
        _ = PassIcon.vaultIcon23Small
        _ = PassIcon.vaultIcon24Big
        _ = PassIcon.vaultIcon24Small
        _ = PassIcon.vaultIcon25Big
        _ = PassIcon.vaultIcon25Small
        _ = PassIcon.vaultIcon26Big
        _ = PassIcon.vaultIcon26Small
        _ = PassIcon.vaultIcon27Big
        _ = PassIcon.vaultIcon27Small
        _ = PassIcon.vaultIcon28Big
        _ = PassIcon.vaultIcon28Small
        _ = PassIcon.vaultIcon29Big
        _ = PassIcon.vaultIcon29Small
        _ = PassIcon.vaultIcon30Big
        _ = PassIcon.vaultIcon30Small

        _ = PassIcon.inviteBannerIcon
        _ = PassIcon.netShield
        _ = PassIcon.sentinelLogo
        
        _ = PassIcon.tabAuthenticator
        _ = PassIcon.shield2
        _ = PassIcon.passPlus
        _ = PassIcon.lightning
        _ = PassIcon.passSubscriptionBadge
        _ = PassIcon.breachShieldResolved
        _ = PassIcon.breachShieldUnresolved
        _ = PassIcon.securityEmptyState
        _ = PassIcon.passSubscriptionUnlimited

        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
}
