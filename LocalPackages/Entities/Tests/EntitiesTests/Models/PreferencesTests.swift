//
// PreferencesTests.swift
// Proton Pass - Created on 04/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Entities
import Foundation
import Testing

@Suite(.tags(.entity))
struct PreferencesTests {
    @Test("Decode AppPreferences from empty JSON")
    func decodeAppPreferencesFromEmptyJson() throws {
        try decodeAndAssert(AppPreferences.self, json: "{}", expectation: .default)
    }

    @Test("Decode AppPreferences from legacy JSON")
    func decodeAppPrerencesFromLegacyJson() throws {
        let json = """
{
    "createdItemsCount": 100
}
"""
        let expectation = AppPreferences(onboarded: AppPreferences.default.onboarded,
                                         telemetryThreshold: AppPreferences.default.telemetryThreshold,
                                         createdItemsCount: 100,
                                         dismissedCustomDomainExplanation:
                                            AppPreferences.default.dismissedCustomDomainExplanation,
                                         hasVisitedContactPage: AppPreferences.default.hasVisitedContactPage,
                                         dismissedFileAttachmentsBanner: AppPreferences.default.dismissedFileAttachmentsBanner,
                                         dismissedUIElements: AppPreferences.default.dismissedUIElements)
        try decodeAndAssert(AppPreferences.self, json: json, expectation: expectation)
    }

    @Test("Decode SharedPreferences from empty JSON")
    func testDecodeSharedPreferencesFromEmptyJson() throws {
        try decodeAndAssert(SharedPreferences.self, json: "{}", expectation: .default)
    }

    @Test("Decode SharedPreferences from legacy JSON")
    func decodeSharedPrerencesFromLegacyJson() throws {
        let json = """
{
    "shareClipboard": true,
    "localAuthenticationMethod": {
        "pin": {}
    },
    "clipboardExpiration": 2}
"""
        let defaultObject = SharedPreferences.default
        let expectation = SharedPreferences(
            quickTypeBar: defaultObject.quickTypeBar,
            automaticallyCopyTotpCode: defaultObject.automaticallyCopyTotpCode,
            theme: defaultObject.theme,
            browser: defaultObject.browser,
            displayFavIcons: defaultObject.displayFavIcons,
            failedAttemptCount: defaultObject.failedAttemptCount,
            localAuthenticationMethod: .pin,
            pinCode: defaultObject.pinCode,
            fallbackToPasscode: SharedPreferences.default.fallbackToPasscode,
            appLockTime: defaultObject.appLockTime,
            clipboardExpiration: .twoMinutes,
            shareClipboard: true, 
            alwaysShowUsernameField: false,
            lastActiveTimestamp: nil,
            aliasDiscovery: [])
        try decodeAndAssert(SharedPreferences.self, json: json, expectation: expectation)
    }

    @Test("Decode UserPreferences from empty JSON")
    func decodeUserPreferencesFromEmptyJson() throws {
        try decodeAndAssert(UserPreferences.self, json: "{}", expectation: .default)
    }

    @Test("Decode UserPreferences from legacy JSON")
    func decodeUserPrerencesFromLegacyJson() throws {
        let json = """
{
    "spotlightSearchableContent": 2
}
"""
        let expectation = UserPreferences(
            spotlightEnabled: UserPreferences.default.spotlightEnabled,
            spotlightSearchableContent: .allExceptSensitiveData,
            spotlightSearchableVaults: UserPreferences.default.spotlightSearchableVaults, 
            extraPasswordEnabled: UserPreferences.default.extraPasswordEnabled, 
            protonPasswordFailedVerificationCount: UserPreferences.default.protonPasswordFailedVerificationCount, 
            lastSelectedShareId: UserPreferences.default.lastSelectedShareId,
            lastCreatedItemShareId: UserPreferences.default.lastCreatedItemShareId,
            dismissedAliasesSyncSheet: UserPreferences.default.dismissedAliasesSyncSheet)
        try decodeAndAssert(UserPreferences.self, json: json, expectation: expectation)
    }

    func decodeAndAssert<T: Decodable & Equatable>(_ type: T.Type, json: String, expectation: T) throws {
        let data = try #require(json.data(using: .utf8))
        let result = try JSONDecoder().decode(T.self, from: data)
        #expect(result == expectation)
    }
}
