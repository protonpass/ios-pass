// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
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
import Entities
import PassRustCore

public final class ItemWeaknessEvaluatorProtocolMock: @unchecked Sendable, ItemWeaknessEvaluatorProtocol {

    public init() {}

    // MARK: - evaluate
    public var closureEvaluate: () -> () = {}
    public var invokedEvaluatefunction = false
    public var invokedEvaluateCount = 0
    public var invokedEvaluateParameters: (login: LogInItemData, isReused: Bool)?
    public var invokedEvaluateParametersList = [(login: LogInItemData, isReused: Bool)]()
    public nonisolated(unsafe) var stubbedEvaluateResult: Set<WeaknessKind>!

    public func evaluate(_ login: LogInItemData, isReused: Bool) -> Set<WeaknessKind> {
        invokedEvaluatefunction = true
        invokedEvaluateCount += 1
        invokedEvaluateParameters = (login, isReused)
        closureEvaluate()
        return stubbedEvaluateResult
    }
}
