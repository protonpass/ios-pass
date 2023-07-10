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

// swiftlint:disable redundant_optional_initialization
import Client
import Core

private extension KeychainStorage {
    /// Conveniently initialize with injected `keychain`  & `logManager`
    init(wrappedValue: Value, _ key: String) {
        self.init(wrappedValue: wrappedValue,
                  key: key,
                  keychain: SharedToolingContainer.shared.keychain(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

final class Preferences: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }
    init() {}

    @KeychainStorage("quickTypeBar")
    var quickTypeBar = true

    @KeychainStorage("automaticallyCopyTotpCode")
    var automaticallyCopyTotpCode = false

    @KeychainStorage("failedAttemptCount")
    var failedAttemptCount = 0

    @KeychainStorage("biometricAuthenticationEnabled")
    var biometricAuthenticationEnabled = false

    @KeychainStorage("appLockTime")
    var appLockTime: AppLockTime = .twoMinutes

    @KeychainStorage("onboarded")
    var onboarded = false

    @KeychainStorage("autoFillBannerDisplayed")
    var autoFillBannerDisplayed = false

    @KeychainStorage("theme")
    var theme = Theme.dark

    @KeychainStorage("browser")
    var browser = Browser.safari

    @KeychainStorage("clipboardExpiration")
    var clipboardExpiration = ClipboardExpiration.oneMinute

    @KeychainStorage("shareClipboard")
    var shareClipboard = false

    @KeychainStorage("telemetryThreshold")
    var telemetryThreshold: TimeInterval? = nil

    @KeychainStorage("displayFavIcons")
    var displayFavIcons = true

    @KeychainStorage("dismissedBannerIds")
    var dismissedBannerIds = [String]()

    @KeychainStorage("isFirstRun")
    public var isFirstRun = true

    @KeychainStorage("createdItemsCount")
    public var createdItemsCount = 0

    public func reset(isUITests: Bool = false) {
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
    public func getThreshold() -> TimeInterval? { telemetryThreshold }
    public func setThreshold(_ threshold: TimeInterval?) { telemetryThreshold = threshold }
}

// MARK: - FavIconSettings

extension Preferences: FavIconSettings {
    public var shouldDisplayFavIcons: Bool { displayFavIcons }
}

// swiftlint:enable redundant_optional_initialization
