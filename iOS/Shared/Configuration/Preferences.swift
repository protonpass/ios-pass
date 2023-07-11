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
import SwiftUI

private extension KeychainStorage {
    /// Conveniently initialize with injected `keychain`  & `logManager`
    init(key: any RawRepresentable<String>, defaultValue: Value) {
        self.init(key: key.rawValue,
                  defaultValue: defaultValue,
                  keychain: SharedToolingContainer.shared.keychain(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

final class Preferences: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    init() {}

    // MARK: Non sensitive prefs

    @AppStorage(Key.quickTypeBar.rawValue, store: kSharedUserDefaults)
    var quickTypeBar = true

    @AppStorage(Key.automaticallyCopyTotpCode.rawValue, store: kSharedUserDefaults)
    var automaticallyCopyTotpCode = false

    @AppStorage(Key.onboarded.rawValue, store: kSharedUserDefaults)
    var onboarded = false

    @AppStorage(Key.theme.rawValue, store: kSharedUserDefaults)
    var theme: Theme = .dark

    @AppStorage(Key.browser.rawValue, store: kSharedUserDefaults)
    var browser: Browser = .safari

    @AppStorage(Key.telemetryThreshold.rawValue, store: kSharedUserDefaults)
    var telemetryThreshold: TimeInterval?

    @AppStorage(Key.displayFavIcons.rawValue, store: kSharedUserDefaults)
    var displayFavIcons = true

    @AppStorage(Key.isFirstRun.rawValue, store: kSharedUserDefaults)
    var isFirstRun = true

    @AppStorage(Key.createdItemsCount.rawValue, store: kSharedUserDefaults)
    var createdItemsCount = 0

    // MARK: Sensitive prefs

    @KeychainStorage(key: Key.failedAttemptCount, defaultValue: 0)
    var failedAttemptCount: Int

    @KeychainStorage(key: Key.biometricAuthenticationEnabled, defaultValue: false)
    var biometricAuthenticationEnabled: Bool

    @KeychainStorage(key: Key.appLockTime, defaultValue: .twoMinutes)
    var appLockTime: AppLockTime

    @KeychainStorage(key: Key.clipboardExpiration, defaultValue: .oneMinute)
    var clipboardExpiration: ClipboardExpiration

    @KeychainStorage(key: Key.shareClipboard, defaultValue: false)
    var shareClipboard: Bool

    /// Not really sensitive but `@AppStorage` does not support array so we rely on `@KeychainStorage`
    @KeychainStorage(key: Key.dismissedBannerIds, defaultValue: [])
    var dismissedBannerIds: [String]

    func reset(isTests: Bool = false) {
        quickTypeBar = true
        automaticallyCopyTotpCode = false
        failedAttemptCount = 0
        biometricAuthenticationEnabled = false
        appLockTime = .twoMinutes
        theme = .dark
        browser = .safari
        clipboardExpiration = .oneMinute
        shareClipboard = false
        telemetryThreshold = nil
        displayFavIcons = true
        dismissedBannerIds = []
        if isTests {
            isFirstRun = true
            onboarded = false
            createdItemsCount = 0
        }
    }
}

private extension Preferences {
    enum Key: String {
        case quickTypeBar
        case automaticallyCopyTotpCode
        case failedAttemptCount
        case biometricAuthenticationEnabled
        case appLockTime
        case onboarded
        case theme
        case browser
        case clipboardExpiration
        case shareClipboard
        case telemetryThreshold
        case displayFavIcons
        case dismissedBannerIds
        case isFirstRun
        case createdItemsCount
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
