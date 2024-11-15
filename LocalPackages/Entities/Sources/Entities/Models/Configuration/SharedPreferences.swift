//
// SharedPreferences.swift
// Proton Pass - Created on 03/04/2024.
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

import Foundation
import LocalAuthentication

/// Shared preferences between all users
public struct SharedPreferences: Codable, Equatable, Sendable {
    /// AutoFill suggestions above the keyboard
    public var quickTypeBar: Bool

    /// Automatically copy TOTP code to clipboard after autofilling
    public var automaticallyCopyTotpCode: Bool

    /// Choosen theme
    public var theme: Theme

    /// Choosen browser to open URLs
    public var browser: Browser

    /// Display or not favicon of login items
    public var displayFavIcons: Bool

    /// Number of failed local authentication attempts
    public var failedAttemptCount: Int

    /// Face ID/Touch ID/Optic ID or PIN code authentication
    public var localAuthenticationMethod: LocalAuthenticationMethod

    /// PIN code if local authentication method is PIN
    public var pinCode: String?

    /// Fallback to device's passcode when biometric authentication (Face ID/Touch ID/Optic ID) fails
    public var fallbackToPasscode: Bool

    /// Automatic app lock timeout
    public var appLockTime: AppLockTime

    /// Timeout for content copied to clipboard
    public var clipboardExpiration: ClipboardExpiration

    /// Share clipboard's content to devices logged in with same Apple ID
    public var shareClipboard: Bool

    /// Always display username field when creating or editing login items
    public var alwaysShowUsernameField: Bool

    /// The timestamp of the last usage (host app or any extensions)
    /// This is used as an additional information to decide whether to ask for local authentication or not
    public var lastActiveTimestamp: TimeInterval?

    public var localAuthenticationPolicy: LAPolicy {
        fallbackToPasscode ? .deviceOwnerAuthentication : .deviceOwnerAuthenticationWithBiometrics
    }

    public init(quickTypeBar: Bool,
                automaticallyCopyTotpCode: Bool,
                theme: Theme,
                browser: Browser,
                displayFavIcons: Bool,
                failedAttemptCount: Int,
                localAuthenticationMethod: LocalAuthenticationMethod,
                pinCode: String?,
                fallbackToPasscode: Bool,
                appLockTime: AppLockTime,
                clipboardExpiration: ClipboardExpiration,
                shareClipboard: Bool,
                alwaysShowUsernameField: Bool,
                lastActiveTimestamp: TimeInterval?) {
        self.quickTypeBar = quickTypeBar
        self.automaticallyCopyTotpCode = automaticallyCopyTotpCode
        self.theme = theme
        self.browser = browser
        self.displayFavIcons = displayFavIcons
        self.failedAttemptCount = failedAttemptCount
        self.localAuthenticationMethod = localAuthenticationMethod
        self.pinCode = pinCode
        self.fallbackToPasscode = fallbackToPasscode
        self.appLockTime = appLockTime
        self.clipboardExpiration = clipboardExpiration
        self.shareClipboard = shareClipboard
        self.alwaysShowUsernameField = alwaysShowUsernameField
        self.lastActiveTimestamp = lastActiveTimestamp
    }
}

private extension SharedPreferences {
    enum Default {
        static let quickTypeBar = true
        static let automaticallyCopyTotpCode = true
        static let theme: Theme = .default
        static let browser: Browser = .default
        static let displayFavIcons = true
        static let failedAttemptCount = 0
        static let localAuthenticationMethod: LocalAuthenticationMethod = .default
        static let pinCode: String? = nil
        static let fallbackToPasscode = true
        static let appLockTime: AppLockTime = .default
        static let clipboardExpiration: ClipboardExpiration = .default
        static let shareClipboard = false
        static let alwaysShowUsernameField = false
        static let lastActiveTimestamp: TimeInterval? = nil
    }

    enum CodingKeys: String, CodingKey {
        case quickTypeBar
        case automaticallyCopyTotpCode
        case theme
        case browser
        case displayFavIcons
        case failedAttemptCount
        case localAuthenticationMethod
        case pinCode
        case fallbackToPasscode
        case appLockTime
        case clipboardExpiration
        case shareClipboard
        case alwaysShowUsernameField
        case lastActiveTimestamp
    }
}

public extension SharedPreferences {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let quickTypeBar = try container.decodeIfPresent(Bool.self, forKey: .quickTypeBar)
        let automaticallyCopyTotpCode = try container.decodeIfPresent(Bool.self,
                                                                      forKey: .automaticallyCopyTotpCode)
        let theme = try container.decodeIfPresent(Theme.self, forKey: .theme)
        let browser = try container.decodeIfPresent(Browser.self, forKey: .browser)
        let displayFavIcons = try container.decodeIfPresent(Bool.self, forKey: .displayFavIcons)
        let failedAttemptCount = try container.decodeIfPresent(Int.self, forKey: .failedAttemptCount)
        let localAuthenticationMethod = try container.decodeIfPresent(LocalAuthenticationMethod.self,
                                                                      forKey: .localAuthenticationMethod)
        let pinCode = try container.decodeIfPresent(String.self, forKey: .pinCode)
        let fallbackToPasscode = try container.decodeIfPresent(Bool.self, forKey: .fallbackToPasscode)
        let appLockTime = try container.decodeIfPresent(AppLockTime.self, forKey: .appLockTime)
        let clipboardExpiration = try container.decodeIfPresent(ClipboardExpiration.self,
                                                                forKey: .clipboardExpiration)
        let shareClipboard = try container.decodeIfPresent(Bool.self, forKey: .shareClipboard)
        let alwaysShowUsernameField = try container.decodeIfPresent(Bool.self, forKey: .alwaysShowUsernameField)
        let lastActiveTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .lastActiveTimestamp)
        self.init(quickTypeBar: quickTypeBar ?? Default.quickTypeBar,
                  automaticallyCopyTotpCode: automaticallyCopyTotpCode ?? Default.automaticallyCopyTotpCode,
                  theme: theme ?? Default.theme,
                  browser: browser ?? Default.browser,
                  displayFavIcons: displayFavIcons ?? Default.displayFavIcons,
                  failedAttemptCount: failedAttemptCount ?? Default.failedAttemptCount,
                  localAuthenticationMethod: localAuthenticationMethod ?? Default.localAuthenticationMethod,
                  pinCode: pinCode ?? Default.pinCode,
                  fallbackToPasscode: fallbackToPasscode ?? Default.fallbackToPasscode,
                  appLockTime: appLockTime ?? Default.appLockTime,
                  clipboardExpiration: clipboardExpiration ?? Default.clipboardExpiration,
                  shareClipboard: shareClipboard ?? Default.shareClipboard,
                  alwaysShowUsernameField: alwaysShowUsernameField ?? Default.alwaysShowUsernameField,
                  lastActiveTimestamp: lastActiveTimestamp ?? Default.lastActiveTimestamp)
    }
}

extension SharedPreferences: Defaultable {
    public static var `default`: Self {
        .init(quickTypeBar: Default.quickTypeBar,
              automaticallyCopyTotpCode: Default.automaticallyCopyTotpCode,
              theme: Default.theme,
              browser: Default.browser,
              displayFavIcons: Default.displayFavIcons,
              failedAttemptCount: Default.failedAttemptCount,
              localAuthenticationMethod: Default.localAuthenticationMethod,
              pinCode: Default.pinCode,
              fallbackToPasscode: Default.fallbackToPasscode,
              appLockTime: Default.appLockTime,
              clipboardExpiration: Default.clipboardExpiration,
              shareClipboard: Default.shareClipboard,
              alwaysShowUsernameField: Default.alwaysShowUsernameField,
              lastActiveTimestamp: Default.lastActiveTimestamp)
    }
}
