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
import XCTest

final class PreferencesTests: XCTestCase {
    func testDecodeAppPreferencesFromEmptyJson() throws {
        try decodeAndAssert(AppPreferences.self, json: "{}", expectation: .default)
    }

    func testDecodeAppPrerencesFromLegacyJson() throws {
        let json = """
{
    "createdItemsCount": 100,
    "dismissedBannerIds": ["a", "b", "c"]
}
"""
        let expectation = AppPreferences(onboarded: AppPreferences.default.onboarded,
                                         telemetryThreshold: AppPreferences.default.telemetryThreshold,
                                         createdItemsCount: 100,
                                         dismissedBannerIds: ["a", "b", "c"], 
                                         dismissedCustomDomainExplanation:
                                            AppPreferences.default.dismissedCustomDomainExplanation,
                                         didMigratePreferences: AppPreferences.default.didMigratePreferences, 
                                         dismissedAliasesSyncExplanation: AppPreferences.default.dismissedAliasesSyncExplanation)
        try decodeAndAssert(AppPreferences.self, json: json, expectation: expectation)
    }

    func testDecodeSharedPreferencesFromEmptyJson() throws {
        try decodeAndAssert(SharedPreferences.self, json: "{}", expectation: .default)
    }

    func testDecodeSharedPrerencesFromLegacyJson() throws {
        let json = """
{
    "shareClipboard": true,
    "localAuthenticationMethod": {
        "pin": {}
    },
    "clipboardExpiration": 2
}
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
            alwaysShowUsernameField: false)
        try decodeAndAssert(SharedPreferences.self, json: json, expectation: expectation)
    }

    func testDecodeUserPreferencesFromEmptyJson() throws {
        try decodeAndAssert(UserPreferences.self, json: "{}", expectation: .default)
    }

    func testDecodeUserPrerencesFromLegacyJson() throws {
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
            lastCreatedItemShareId: UserPreferences.default.lastCreatedItemShareId)
        try decodeAndAssert(UserPreferences.self, json: json, expectation: expectation)
    }

    func decodeAndAssert<T: Decodable & Equatable>(_ type: T.Type, json: String, expectation: T) throws {
        let data = try XCTUnwrap(json.data(using: .utf8))
        let result = try JSONDecoder().decode(T.self, from: data)
        XCTAssertEqual(result, expectation)
    }
}
