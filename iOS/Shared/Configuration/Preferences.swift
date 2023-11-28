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
import Entities
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

/// User's personal preferences as well as settings related to app's functionalities
/// Not all preference are saved the same way, some of them are sensitive while others aren't
///
/// Use `@KeychainStorage` for sensitive data that need to resists app's filesystem inspection & modification
/// Be aware that data stored by `@KeychainStorage` survive reinstallations
/// Consider using this property wrapper when dealing with data that relates to access to the app
/// (custom PIN code, the number of failed authentication attempts, whether biometric authentication is enabled or
/// not...)
///
/// Use `@AppStorage` for trivial data that do not need to survive reinstallations
/// Consider using this property wrapper for data that can be lost without any security impacts
/// (theme settings, selected browser...)
final class Preferences: ObservableObject, DeinitPrintable, PreferencesProtocol {
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
    var browser: Browser = .systemDefault

    @MainActor @AppStorage(Key.telemetryThreshold.rawValue, store: kSharedUserDefaults)
    var telemetryThreshold: TimeInterval?

    @AppStorage(Key.displayFavIcons.rawValue, store: kSharedUserDefaults)
    var displayFavIcons = true

    @AppStorage(Key.isFirstRun.rawValue, store: kSharedUserDefaults)
    var isFirstRun = true

    @AppStorage(Key.createdItemsCount.rawValue, store: kSharedUserDefaults)
    var createdItemsCount = 0

    @AppStorage(Key.didMigrateToSeparatedCredentials.rawValue, store: kSharedUserDefaults)
    var didMigrateToSeparatedCredentials = false

    // MARK: Sensitive prefs

    @KeychainStorage(key: Key.failedAttemptCount, defaultValue: 0)
    var failedAttemptCount: Int

    @KeychainStorage(key: Key.localAuthenticationMethod, defaultValue: .none)
    var localAuthenticationMethod: LocalAuthenticationMethod

    @KeychainStorage(key: Key.pinCode, defaultValue: nil)
    var pinCode: String?

    @KeychainStorage(key: Key.fallbackToPasscode, defaultValue: true)
    var fallbackToPasscode: Bool

    @KeychainStorage(key: Key.appLockTime, defaultValue: .twoMinutes)
    var appLockTime: AppLockTime

    @KeychainStorage(key: Key.clipboardExpiration, defaultValue: .twoMinutes)
    var clipboardExpiration: ClipboardExpiration

    @KeychainStorage(key: Key.shareClipboard, defaultValue: false)
    var shareClipboard: Bool

    /// Not really sensitive but `@AppStorage` does not support array so we rely on `@KeychainStorage`
    @KeychainStorage(key: Key.dismissedBannerIds, defaultValue: [])
    var dismissedBannerIds: [String]

    @MainActor
    func reset(isTests: Bool = false) {
        quickTypeBar = true
        automaticallyCopyTotpCode = false
        failedAttemptCount = 0
        localAuthenticationMethod = .none
        fallbackToPasscode = true
        pinCode = nil
        appLockTime = .twoMinutes
        theme = .dark
        browser = .systemDefault
        clipboardExpiration = .twoMinutes
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
        case localAuthenticationMethod
        case pinCode
        case fallbackToPasscode
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

        // Temporary keys, can be removed several versions after 1.5.7
        case didMigrateToSeparatedCredentials
    }
}

// MARK: - TelemetryThresholdProviderProtocol

extension Preferences: TelemetryThresholdProviderProtocol {
    @MainActor func getThreshold() -> TimeInterval? { telemetryThreshold }
    @MainActor func setThreshold(_ threshold: TimeInterval?) { telemetryThreshold = threshold }
}

// MARK: - FavIconSettings

extension Preferences: FavIconSettings {
    var shouldDisplayFavIcons: Bool { displayFavIcons }
}
