//
// Preferences.swift
// Proton Pass - Created on 05/10/2022.
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

import Client
import Core

private extension KeychainStorage {
    /// Conveniently initialize with injected `keychain`  & `logManager`
    init(key: String, defaultValue: Value) {
        self.init(key: key,
                  defaultValue: defaultValue,
                  keychain: SharedToolingContainer.shared.keychain(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

final class Preferences: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    init() {}

    @KeychainStorage(key: "quickTypeBar", defaultValue: true)
    var quickTypeBar: Bool

    @KeychainStorage(key: "automaticallyCopyTotpCode", defaultValue: false)
    var automaticallyCopyTotpCode: Bool

    @KeychainStorage(key: "failedAttemptCount", defaultValue: 0)
    var failedAttemptCount: Int

    @KeychainStorage(key: "biometricAuthenticationEnabled", defaultValue: false)
    var biometricAuthenticationEnabled: Bool

    @KeychainStorage(key: "appLockTime", defaultValue: .twoMinutes)
    var appLockTime: AppLockTime

    @KeychainStorage(key: "onboarded", defaultValue: false)
    var onboarded: Bool

    @KeychainStorage(key: "autoFillBannerDisplayed", defaultValue: false)
    var autoFillBannerDisplayed: Bool

    @KeychainStorage(key: "theme", defaultValue: .dark)
    var theme: Theme

    @KeychainStorage(key: "browser", defaultValue: .safari)
    var browser: Browser

    @KeychainStorage(key: "clipboardExpiration", defaultValue: .oneMinute)
    var clipboardExpiration: ClipboardExpiration

    @KeychainStorage(key: "shareClipboard", defaultValue: false)
    var shareClipboard: Bool

    @KeychainStorage(key: "telemetryThreshold", defaultValue: nil)
    var telemetryThreshold: TimeInterval?

    @KeychainStorage(key: "displayFavIcons", defaultValue: true)
    var displayFavIcons: Bool

    @KeychainStorage(key: "dismissedBannerIds", defaultValue: [])
    var dismissedBannerIds: [String]

    @KeychainStorage(key: "isFirstRun", defaultValue: true)
    var isFirstRun: Bool

    @KeychainStorage(key: "createdItemsCount", defaultValue: 0)
    var createdItemsCount: Int

    func reset(isUITests: Bool = false) {
        quickTypeBar = true
        automaticallyCopyTotpCode = false
        failedAttemptCount = 0
        biometricAuthenticationEnabled = false
        appLockTime = .twoMinutes
        autoFillBannerDisplayed = false
        theme = .dark
        browser = .safari
        clipboardExpiration = .oneMinute
        shareClipboard = false
        telemetryThreshold = nil
        displayFavIcons = true
        dismissedBannerIds = []
        if isUITests {
            onboarded = false
        }
    }
}

// MARK: - TelemetryThresholdProviderProtocol

extension Preferences: TelemetryThresholdProviderProtocol {
    func getThreshold() -> TimeInterval? { telemetryThreshold }
    func setThreshold(_ threshold: TimeInterval?) { telemetryThreshold = threshold }
}

// MARK: - FavIconSettings

extension Preferences: FavIconSettings {
    var shouldDisplayFavIcons: Bool { displayFavIcons }
}
