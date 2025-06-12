// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import Combine
import Core
import Entities
import Foundation

public final class ThemeProviderMock: @unchecked Sendable, ThemeProvider {

    public init() {}

    // MARK: - sharedPreferences
    public var invokedSharedPreferencesSetter = false
    public var invokedSharedPreferencesSetterCount = 0
    public var invokedSharedPreferences: CurrentValueSubject<SharedPreferences?, Never>?
    public var invokedSharedPreferencesList = [CurrentValueSubject<SharedPreferences?, Never>?]()
    public var invokedSharedPreferencesGetter = false
    public var invokedSharedPreferencesGetterCount = 0
    public var stubbedSharedPreferences: CurrentValueSubject<SharedPreferences?, Never>!
    public var sharedPreferences: CurrentValueSubject<SharedPreferences?, Never> {
        set {
            invokedSharedPreferencesSetter = true
            invokedSharedPreferencesSetterCount += 1
            invokedSharedPreferences = newValue
            invokedSharedPreferencesList.append(newValue)
        } get {
            invokedSharedPreferencesGetter = true
            invokedSharedPreferencesGetterCount += 1
            return stubbedSharedPreferences
        }
    }
}
