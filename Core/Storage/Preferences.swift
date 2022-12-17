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

private let kSharedUserDefaults = UserDefaults(suiteName: Constants.appGroup)

public final class Preferences: ObservableObject {
    public init() {}

    @AppStorage("quickTypeBar", store: kSharedUserDefaults)
    public var quickTypeBar = true

    @AppStorage("failedAttemptCount", store: kSharedUserDefaults)
    public var failedAttemptCount = 0

    @AppStorage("biometricAuthenticationEnabled", store: kSharedUserDefaults)
    public var biometricAuthenticationEnabled = false

    @AppStorage("onboarded", store: kSharedUserDefaults)
    public var onboarded = false

    @AppStorage("autoFillBannerDisplayed", store: kSharedUserDefaults)
    public var autoFillBannerDisplayed = false

    public func reset() {
        quickTypeBar = true
        failedAttemptCount = 0
        biometricAuthenticationEnabled = false
        autoFillBannerDisplayed = false
    }
}
