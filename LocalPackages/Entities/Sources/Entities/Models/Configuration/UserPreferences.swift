//
// UserPreferences.swift
// Proton Pass - Created on 27/03/2024.
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

/// Preferences bound to a specific user
public struct UserPreferences: Codable, Equatable {
    /// AutoFill suggestions above the keyboard
    public var quickTypeBar = true

    /// Automatically copy TOTP code to clipboard after autofilling
    public var automaticallyCopyTotpCode = true

    /// Choosen theme
    public var theme: Theme = .dark

    /// Choosen browser to open URLs
    public var browser: Browser = .systemDefault

    /// Display or not favicon of login items
    public var displayFavIcons = true

    /// Number of failed local authentication attempts
    public var failedAttemptCount = 0

    /// Face ID/Touch ID/Optic ID or PIN code authentication
    public var localAuthenticationMethod: LocalAuthenticationMethod = .none

    /// PIN code if local authentication method is PIN
    public var pinCode: String?

    /// Fallback to device's passcode when biometric authentication (Face ID/Touch ID/Optic ID) fails
    public var fallbackToPasscode = true

    /// Automatic app lock timeout
    public var appLockTime: AppLockTime = .twoMinutes

    /// Timeout for content copied to clipboard
    public var clipboardExpiration: ClipboardExpiration = .twoMinutes

    /// Share clipboard's content to devices logged in with same Apple ID
    public var shareClipboard = false

    /// Searchable items via Spotlight
    public var spotlightEnabled = false

    /// Spotlight indexable item content type
    public var spotlightSearchableContent: SpotlightSearchableContent = .title

    /// Spotlight indexable vaults
    public var spotlightSearchableVaults: SpotlightSearchableVaults = .all

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
                spotlightEnabled: Bool,
                spotlightSearchableContent: SpotlightSearchableContent,
                spotlightSearchableVaults: SpotlightSearchableVaults) {
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
        self.spotlightEnabled = spotlightEnabled
        self.spotlightSearchableContent = spotlightSearchableContent
        self.spotlightSearchableVaults = spotlightSearchableVaults
    }
}
