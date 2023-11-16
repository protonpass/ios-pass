//
// PreferencesTests.swift
// Proton Pass - Created on 02/03/2023.
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

import Factory
@testable import Proton_Pass
import XCTest

final class PreferencesTests: XCTestCase {
    var sut: Preferences!

    override func setUp() {
        super.setUp()
        sut = Preferences()
    }

    override func tearDown() {
        sut.reset(isTests: true)
        sut = nil
        super.tearDown()
    }

    func testQuickTypeBarEnabledByDefault() {
        XCTAssertTrue(sut.quickTypeBar)
    }

    func testQuickTypeBarEnabledAfterResetting() {
        sut.quickTypeBar = false
        XCTAssertFalse(sut.quickTypeBar)
        sut.reset()
        XCTAssertTrue(sut.quickTypeBar)
    }

    func testAutomaticallyCopyTotpCodeDisabledByDefault() {
        XCTAssertFalse(sut.automaticallyCopyTotpCode)
    }

    func testAutomaticallyCopyTotpCodeDisabledAfterResetting() {
        sut.automaticallyCopyTotpCode = true
        XCTAssertTrue(sut.automaticallyCopyTotpCode)
        sut.reset()
        XCTAssertFalse(sut.automaticallyCopyTotpCode)
    }

    func testFailedAttemptCountZeroByDefault() {
        XCTAssertEqual(sut.failedAttemptCount, 0)
    }

    func testFailedAttempCountZeroAfterResetting() {
        sut.failedAttemptCount = 1
        XCTAssertEqual(sut.failedAttemptCount, 1)
        sut.failedAttemptCount = 2
        XCTAssertEqual(sut.failedAttemptCount, 2)
        sut.reset()
        XCTAssertEqual(sut.failedAttemptCount, 0)
    }

    func testLocalAuthenticationMethodNoneByDefault() {
        XCTAssertEqual(sut.localAuthenticationMethod, .none)
    }

    func testLocalAuthenticationMethodIsNoneAfterResetting() {
        sut.localAuthenticationMethod = .pin
        XCTAssertEqual(sut.localAuthenticationMethod, .pin)
        sut.reset()
        XCTAssertEqual(sut.localAuthenticationMethod, .none)
    }

    func testFallbackToPasscodeByDefault() {
        XCTAssertTrue(sut.fallbackToPasscode)
    }

    func testFallbackToPasscodeAfterResetting() {
        sut.fallbackToPasscode = false
        XCTAssertFalse(sut.fallbackToPasscode)
        sut.reset()
        XCTAssertTrue(sut.fallbackToPasscode)
    }

    func testPinCodeIsNilByDefault() {
        XCTAssertNil(sut.pinCode)
    }

    func testPinCodeIsNilAfterResetting() {
        let pinCode = String.random()
        sut.pinCode = pinCode
        XCTAssertEqual(sut.pinCode, pinCode)
        sut.reset()
        XCTAssertNil(sut.pinCode)
    }

    func testAppLockTimeIsTwoMinutesByDefault() {
        XCTAssertEqual(sut.appLockTime, .twoMinutes)
    }

    func testAppLockTimeIsTwoMinutesAfterResetting() {
        sut.appLockTime = .fourHours
        XCTAssertEqual(sut.appLockTime, .fourHours)
        sut.reset()
        XCTAssertEqual(sut.appLockTime, .twoMinutes)
    }

    func testNotOnboardedByDefault() {
        XCTAssertFalse(sut.onboarded)
    }

    func testOnboardJustOnce() {
        sut.onboarded = true
        XCTAssertTrue(sut.onboarded)
        sut.reset()
        XCTAssertTrue(sut.onboarded)
    }

    func testOnboardOnEveryUITestCase() {
        sut.onboarded = true
        XCTAssertTrue(sut.onboarded)
        sut.reset(isTests: true)
        XCTAssertFalse(sut.onboarded)
    }

    func testThemeIsDarkByDefault() {
        XCTAssertEqual(sut.theme, .dark)
    }

    func testThemeIsDarkAfterResetting() {
        sut.theme = .light
        XCTAssertEqual(sut.theme, .light)
        sut.theme = .matchSystem
        XCTAssertEqual(sut.theme, .matchSystem)
        sut.reset()
        XCTAssertEqual(sut.theme, .dark)
    }

    func testBrowserIsSystemDefaultByDefault() {
        XCTAssertEqual(sut.browser, .systemDefault)
    }

    func testBrowserIsSystemDefaultAfterResetting() {
        sut.browser = .inAppSafari
        XCTAssertEqual(sut.browser, .inAppSafari)
        sut.browser = .safari
        XCTAssertEqual(sut.browser, .safari)
        sut.reset()
        XCTAssertEqual(sut.browser, .systemDefault)
    }

    func testClipboardExpiresAfterOneMinuteByDefault() {
        XCTAssertEqual(sut.clipboardExpiration, .oneMinute)
    }

    func testClipboardExpiresAfterOneMinuteAfterResetting() {
        sut.clipboardExpiration = .fifteenSeconds
        XCTAssertEqual(sut.clipboardExpiration, .fifteenSeconds)
        sut.reset()
        XCTAssertEqual(sut.clipboardExpiration, .oneMinute)
    }

    func testDoNotShareClipboardByDefault() {
        XCTAssertFalse(sut.shareClipboard)
    }

    func testDoNotShareClipboardAfterResetting() {
        sut.shareClipboard = true
        XCTAssertTrue(sut.shareClipboard)
        sut.reset()
        XCTAssertFalse(sut.shareClipboard)
    }

    func testTelemetryThresholdNilByDefault() {
        XCTAssertNil(sut.telemetryThreshold)
    }

    func testTelemetryThresholdNilAfterResetting() {
        let date = Date.now
        sut.telemetryThreshold = date.timeIntervalSince1970
        XCTAssertEqual(sut.telemetryThreshold, date.timeIntervalSince1970)
        sut.reset()
        XCTAssertNil(sut.telemetryThreshold)
    }

    func testDisplayFavIconsEnabledByDefault() {
        XCTAssertTrue(sut.displayFavIcons)
    }

    func testDisplayFavIconsEnabledAfterResetting() {
        sut.displayFavIcons = false
        XCTAssertFalse(sut.displayFavIcons)
        sut.reset()
        XCTAssertTrue(sut.displayFavIcons)
    }

    func testGetSetDismissedBannerIds() {
        XCTAssertTrue(sut.dismissedBannerIds.isEmpty)

        let id1 = String.random()
        sut.dismissedBannerIds.append(id1)
        XCTAssertEqual(sut.dismissedBannerIds.count, 1)
        XCTAssertEqual(sut.dismissedBannerIds[0], id1)

        let id2 = String.random()
        sut.dismissedBannerIds.append(id2)
        XCTAssertEqual(sut.dismissedBannerIds.count, 2)
        XCTAssertEqual(sut.dismissedBannerIds[1], id2)

        sut.dismissedBannerIds.removeAll(where: { $0 == id1 })
        XCTAssertEqual(sut.dismissedBannerIds.count, 1)
        XCTAssertEqual(sut.dismissedBannerIds[0], id2)

        sut.dismissedBannerIds.removeAll()
        XCTAssertTrue(sut.dismissedBannerIds.isEmpty)
    }

    func testDismissedBannerIdsIsEmptyAfterResetting() {
        sut.dismissedBannerIds.append(.random())
        XCTAssertFalse(sut.dismissedBannerIds.isEmpty)
        sut.reset()
        XCTAssertTrue(sut.dismissedBannerIds.isEmpty)
    }

    func testIsFirstRunByDefault() {
        XCTAssertTrue(sut.isFirstRun)
    }

    func testNoMoreFirstRunAfterResetting() {
        sut.isFirstRun = false
        XCTAssertFalse(sut.isFirstRun)
        sut.reset()
        XCTAssertFalse(sut.isFirstRun)
    }

    func testCreatedItemsCountZeroByDefault() {
        XCTAssertEqual(sut.createdItemsCount, 0)
    }

    func testCreatedItemsCountNotChangedAfterResetting() {
        sut.createdItemsCount += 1
        XCTAssertEqual(sut.createdItemsCount, 1)
        sut.createdItemsCount += 1
        XCTAssertEqual(sut.createdItemsCount, 2)
        sut.createdItemsCount += 1
        sut.reset()
        XCTAssertEqual(sut.createdItemsCount, 3)
    }
}
