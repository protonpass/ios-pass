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
final class Preferences: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    init() {}

    // MARK: Non sensitive prefs

    @AppStorage(Key.quickTypeBar.rawValue, store: kSharedUserDefaults)
    var quickTypeBar = true

    @AppStorage(Key.automaticallyCopyTotpCode.rawValue, store: kSharedUserDefaults)
    var automaticallyCopyTotpCode = true

    @AppStorage(Key.onboarded.rawValue, store: kSharedUserDefaults)
    var onboarded = false

    @AppStorage(Key.theme.rawValue, store: kSharedUserDefaults)
    var theme: Theme = .dark

    @AppStorage(Key.browser.rawValue, store: kSharedUserDefaults)
    var browser: Browser = .systemDefault

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

    @KeychainStorage(key: Key.spotlightEnabled, defaultValue: false)
    var spotlightEnabled: Bool

    @KeychainStorage(key: Key.spotlightSearchableContent, defaultValue: .title)
    var spotlightSearchableContent: SpotlightSearchableContent

    @KeychainStorage(key: Key.spotlightSearchableVaults, defaultValue: .all)
    var spotlightSearchableVaults: SpotlightSearchableVaults

    /// Not really sensitive but `@AppStorage` does not support array so we rely on `@KeychainStorage`
    @KeychainStorage(key: Key.dismissedBannerIds, defaultValue: [])
    var dismissedBannerIds: [String]
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
        case spotlightEnabled
        case spotlightSearchableContent
        case spotlightSearchableVaults
        case telemetryThreshold
        case displayFavIcons
        case dismissedBannerIds
        case isFirstRun
        case createdItemsCount

        // Temporary keys
        // Can be removed several versions after 1.5.7
        case didMigrateToSeparatedCredentials
        // Can be removed several versions after 1.8.0
        case didMigrateCredentialsToShareExtension
    }
}

extension Preferences: PreferencesMigrator {
    // swiftlint:disable:next large_tuple
    func migratePreferences() -> (AppPreferences, SharedPreferences, UserPreferences) {
        let app = AppPreferences(onboarded: onboarded,
                                 telemetryThreshold: telemetryThreshold,
                                 createdItemsCount: createdItemsCount,
                                 dismissedBannerIds: dismissedBannerIds,
                                 dismissedCustomDomainExplanation: false,
                                 didMigratePreferences: true,
                                 dismissedAliasesSyncExplanation: false)
        let shared = SharedPreferences(quickTypeBar: quickTypeBar,
                                       automaticallyCopyTotpCode: automaticallyCopyTotpCode,
                                       theme: theme,
                                       browser: browser,
                                       displayFavIcons: displayFavIcons,
                                       failedAttemptCount: failedAttemptCount,
                                       localAuthenticationMethod: localAuthenticationMethod,
                                       pinCode: pinCode,
                                       fallbackToPasscode: fallbackToPasscode,
                                       appLockTime: appLockTime,
                                       clipboardExpiration: clipboardExpiration,
                                       shareClipboard: shareClipboard,
                                       alwaysShowUsernameField: false)
        let user = UserPreferences(spotlightEnabled: spotlightEnabled,
                                   spotlightSearchableContent: spotlightSearchableContent,
                                   spotlightSearchableVaults: spotlightSearchableVaults,
                                   extraPasswordEnabled: false,
                                   protonPasswordFailedVerificationCount: 0,
                                   lastSelectedShareId: nil,
                                   lastCreatedItemShareId: nil)
        return (app, shared, user)
    }
}
