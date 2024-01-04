// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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

import UseCases
import Core
import ProtonCoreFeatureFlags

public final class GetFeatureFlagStatusUseCaseMock: @unchecked Sendable, GetFeatureFlagStatusUseCase {

    public init() {}

    // MARK: - executeFlag
    public var closureExecuteFlagAsync1: () -> () = {}
    public var invokedExecuteFlagAsync1 = false
    public var invokedExecuteFlagAsyncCount1 = 0
    public var invokedExecuteFlagAsyncParameters1: (flag: any FeatureFlagTypeProtocol, Void)?
    public var invokedExecuteFlagAsyncParametersList1 = [(flag: any FeatureFlagTypeProtocol, Void)]()
    public var stubbedExecuteFlagAsyncResult1: Bool!

    public func execute(with flag: any FeatureFlagTypeProtocol) async -> Bool {
        invokedExecuteFlagAsync1 = true
        invokedExecuteFlagAsyncCount1 += 1
        invokedExecuteFlagAsyncParameters1 = (flag, ())
        invokedExecuteFlagAsyncParametersList1.append((flag, ()))
        closureExecuteFlagAsync1()
        return stubbedExecuteFlagAsyncResult1
    }
    // MARK: - executeFlag
    public var closureExecuteFlag2: () -> () = {}
    public var invokedExecuteFlag2 = false
    public var invokedExecuteFlagCount2 = 0
    public var invokedExecuteFlagParameters2: (flag: any FeatureFlagTypeProtocol, Void)?
    public var invokedExecuteFlagParametersList2 = [(flag: any FeatureFlagTypeProtocol, Void)]()
    public var stubbedExecuteFlagResult2: Bool!

    public func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        invokedExecuteFlag2 = true
        invokedExecuteFlagCount2 += 1
        invokedExecuteFlagParameters2 = (flag, ())
        invokedExecuteFlagParametersList2.append((flag, ()))
        closureExecuteFlag2()
        return stubbedExecuteFlagResult2
    }
}
