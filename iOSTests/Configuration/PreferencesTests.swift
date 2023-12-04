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

    override func tearDown() async throws {
        await sut.reset(isTests: true)
        sut = nil
        try await super.tearDown()
    }

    func testQuickTypeBarEnabledByDefault() {
        XCTAssertTrue(sut.quickTypeBar)
    }

    func testQuickTypeBarEnabledAfterResetting() async {
        sut.quickTypeBar = false
        XCTAssertFalse(sut.quickTypeBar)
        await sut.reset()
        XCTAssertTrue(sut.quickTypeBar)
    }

    func testAutomaticallyCopyTotpCodeDisabledByDefault() {
        XCTAssertFalse(sut.automaticallyCopyTotpCode)
    }

    func testAutomaticallyCopyTotpCodeDisabledAfterResetting() async {
        sut.automaticallyCopyTotpCode = true
        XCTAssertTrue(sut.automaticallyCopyTotpCode)
        await sut.reset()
        XCTAssertFalse(sut.automaticallyCopyTotpCode)
    }

    func testFailedAttemptCountZeroByDefault() {
        XCTAssertEqual(sut.failedAttemptCount, 0)
    }

    func testFailedAttempCountZeroAfterResetting() async {
        sut.failedAttemptCount = 1
        XCTAssertEqual(sut.failedAttemptCount, 1)
        sut.failedAttemptCount = 2
        XCTAssertEqual(sut.failedAttemptCount, 2)
        await sut.reset()
        XCTAssertEqual(sut.failedAttemptCount, 0)
    }

    func testLocalAuthenticationMethodNoneByDefault() {
        XCTAssertEqual(sut.localAuthenticationMethod, .none)
    }

    func testLocalAuthenticationMethodIsNoneAfterResetting() async {
        sut.localAuthenticationMethod = .pin
        XCTAssertEqual(sut.localAuthenticationMethod, .pin)
        await sut.reset()
        XCTAssertEqual(sut.localAuthenticationMethod, .none)
    }

    func testFallbackToPasscodeByDefault() {
        XCTAssertTrue(sut.fallbackToPasscode)
    }

    func testFallbackToPasscodeAfterResetting() async {
        sut.fallbackToPasscode = false
        XCTAssertFalse(sut.fallbackToPasscode)
        await sut.reset()
        XCTAssertTrue(sut.fallbackToPasscode)
    }

    func testPinCodeIsNilByDefault() {
        XCTAssertNil(sut.pinCode)
    }

    func testPinCodeIsNilAfterResetting() async {
        let pinCode = String.random()
        sut.pinCode = pinCode
        XCTAssertEqual(sut.pinCode, pinCode)
        await sut.reset()
        XCTAssertNil(sut.pinCode)
    }

    func testAppLockTimeIsTwoMinutesByDefault() {
        XCTAssertEqual(sut.appLockTime, .twoMinutes)
    }

    func testAppLockTimeIsTwoMinutesAfterResetting() async {
        sut.appLockTime = .fourHours
        XCTAssertEqual(sut.appLockTime, .fourHours)
        await sut.reset()
        XCTAssertEqual(sut.appLockTime, .twoMinutes)
    }

    func testNotOnboardedByDefault() {
        XCTAssertFalse(sut.onboarded)
    }

    func testOnboardJustOnce() async {
        sut.onboarded = true
        XCTAssertTrue(sut.onboarded)
        await sut.reset()
        XCTAssertTrue(sut.onboarded)
    }

    func testOnboardOnEveryUITestCase() async {
        sut.onboarded = true
        XCTAssertTrue(sut.onboarded)
        await sut.reset(isTests: true)
        XCTAssertFalse(sut.onboarded)
    }

    func testThemeIsDarkByDefault() {
        XCTAssertEqual(sut.theme, .dark)
    }

    func testThemeIsDarkAfterResetting() async {
        sut.theme = .light
        XCTAssertEqual(sut.theme, .light)
        sut.theme = .matchSystem
        XCTAssertEqual(sut.theme, .matchSystem)
        await sut.reset()
        XCTAssertEqual(sut.theme, .dark)
    }

    func testBrowserIsSystemDefaultByDefault() {
        XCTAssertEqual(sut.browser, .systemDefault)
    }

    func testBrowserIsSystemDefaultAfterResetting() async {
        sut.browser = .inAppSafari
        XCTAssertEqual(sut.browser, .inAppSafari)
        sut.browser = .safari
        XCTAssertEqual(sut.browser, .safari)
        await sut.reset()
        XCTAssertEqual(sut.browser, .systemDefault)
    }

    func testClipboardExpiresAfterTwoMinuteByDefault() {
        XCTAssertEqual(sut.clipboardExpiration, .twoMinutes)
    }

    func testClipboardExpiresAfterTwoMinuteAfterResetting() async {
        sut.clipboardExpiration = .fifteenSeconds
        XCTAssertEqual(sut.clipboardExpiration, .fifteenSeconds)
        await sut.reset()
        XCTAssertEqual(sut.clipboardExpiration, .twoMinutes)
    }

    func testDoNotShareClipboardByDefault() {
        XCTAssertFalse(sut.shareClipboard)
    }

    func testDoNotShareClipboardAfterResetting() async {
        sut.shareClipboard = true
        XCTAssertTrue(sut.shareClipboard)
        await sut.reset()
        XCTAssertFalse(sut.shareClipboard)
    }

    @MainActor
    func testTelemetryThresholdNilByDefault() {
        XCTAssertNil(sut.telemetryThreshold)
    }

    @MainActor
    func testTelemetryThresholdNilAfterResetting() async {
        let date = Date.now
        sut.telemetryThreshold = date.timeIntervalSince1970
        XCTAssertEqual(sut.telemetryThreshold, date.timeIntervalSince1970)
        sut.reset()
        XCTAssertNil(sut.telemetryThreshold)
    }

    func testDisplayFavIconsEnabledByDefault() {
        XCTAssertTrue(sut.displayFavIcons)
    }

    func testDisplayFavIconsEnabledAfterResetting() async {
        sut.displayFavIcons = false
        XCTAssertFalse(sut.displayFavIcons)
        await sut.reset()
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

    func testDismissedBannerIdsIsEmptyAfterResetting() async {
        sut.dismissedBannerIds.append(.random())
        XCTAssertFalse(sut.dismissedBannerIds.isEmpty)
        await sut.reset()
        XCTAssertTrue(sut.dismissedBannerIds.isEmpty)
    }

    func testIsFirstRunByDefault() {
        XCTAssertTrue(sut.isFirstRun)
    }

    func testNoMoreFirstRunAfterResetting() async {
        sut.isFirstRun = false
        XCTAssertFalse(sut.isFirstRun)
        await sut.reset()
        XCTAssertFalse(sut.isFirstRun)
    }

    func testCreatedItemsCountZeroByDefault() {
        XCTAssertEqual(sut.createdItemsCount, 0)
    }

    func testCreatedItemsCountNotChangedAfterResetting() async {
        sut.createdItemsCount += 1
        XCTAssertEqual(sut.createdItemsCount, 1)
        sut.createdItemsCount += 1
        XCTAssertEqual(sut.createdItemsCount, 2)
        sut.createdItemsCount += 1
        await sut.reset()
        XCTAssertEqual(sut.createdItemsCount, 3)
    }
}
