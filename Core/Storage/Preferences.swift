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

import SwiftUI

// swiftlint:disable:next force_unwrapping
public let kSharedUserDefaults = UserDefaults(suiteName: Constants.appGroup)!

public final class Preferences: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }
    public init() {}

    @AppStorage("quickTypeBar", store: kSharedUserDefaults)
    public var quickTypeBar = true

    @AppStorage("automaticallyCopyTotpCode", store: kSharedUserDefaults)
    public var automaticallyCopyTotpCode = false

    @AppStorage("failedAttemptCount", store: kSharedUserDefaults)
    public var failedAttemptCount = 0

    @AppStorage("biometricAuthenticationEnabled", store: kSharedUserDefaults)
    public var biometricAuthenticationEnabled = false

    @AppStorage("appLockTime", store: kSharedUserDefaults)
    public var appLockTime: AppLockTime = .twoMinutes

    @AppStorage("onboarded", store: kSharedUserDefaults)
    public var onboarded = false

    @AppStorage("autoFillBannerDisplayed", store: kSharedUserDefaults)
    public var autoFillBannerDisplayed = false

    @AppStorage("theme", store: kSharedUserDefaults)
    public var theme = Theme.dark

    @AppStorage("browser", store: kSharedUserDefaults)
    public var browser = Browser.safari

    @AppStorage("clipboardExpiration", store: kSharedUserDefaults)
    public var clipboardExpiration = ClipboardExpiration.oneMinute

    @AppStorage("shareClipboard", store: kSharedUserDefaults)
    public var shareClipboard = false

    @AppStorage("telemetryThreshold", store: kSharedUserDefaults)
    public var telemetryThreshold: TimeInterval?

    @AppStorage("displayFavIcons", store: kSharedUserDefaults)
    public var displayFavIcons = true

    /// A list of IDs of banners that are dismissed by users.
    /// `AppStorage` does not support array out of the box so these IDs are concatenated and separated by `,`
    /// E.g: when trial & autofill banners are dismissed, this is how the string looks like `"trial,autofill"`
    @AppStorage("dismissedBannerIds", store: kSharedUserDefaults)
    private var _dismissedBannerIds = ""

    public var dismissedBannerIds: [String] {
        get {
            _dismissedBannerIds.components(separatedBy: ",").filter { !$0.isEmpty }
        }
        set {
            _dismissedBannerIds = newValue.joined(separator: ",")
        }
    }

    @AppStorage("isFirstRun", store: kSharedUserDefaults)
    public var isFirstRun = true

    /// Temporary boolean. Can be removed after going public.
    @AppStorage("didReencryptAllItems", store: kSharedUserDefaults)
    public var didReencryptAllItems = false

    @AppStorage("createdItemsCount", store: kSharedUserDefaults)
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
        _dismissedBannerIds = ""
        if isUITests {
            onboarded = false
        }
    }
}
