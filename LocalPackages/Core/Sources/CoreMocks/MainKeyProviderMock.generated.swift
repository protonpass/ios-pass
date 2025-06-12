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

import Core
import ProtonCoreKeymaker
import ProtonCoreSettings

public final class MainKeyProviderMock: @unchecked Sendable, MainKeyProvider {

    public init() {}

    // MARK: - mainKey
    public var invokedMainKeySetter = false
    public var invokedMainKeySetterCount = 0
    public var invokedMainKey: MainKey?
    public var invokedMainKeyList = [MainKey?]()
    public var invokedMainKeyGetter = false
    public var invokedMainKeyGetterCount = 0
    public var stubbedMainKey: MainKey!
    public var mainKey: MainKey? {
        set {
            invokedMainKeySetter = true
            invokedMainKeySetterCount += 1
            invokedMainKey = newValue
            invokedMainKeyList.append(newValue)
        } get {
            invokedMainKeyGetter = true
            invokedMainKeyGetterCount += 1
            return stubbedMainKey
        }
    }
}
