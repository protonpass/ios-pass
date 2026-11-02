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

import UseCases
import Core
import Entities
import Security

public final class GenerateRuleCompliantPasswordUseCaseMock: @unchecked Sendable, GenerateRuleCompliantPasswordUseCase {

    public init() {}

    // MARK: - callAsFunction
    public var closureCallAsFunction: () -> () = {}
    public var invokedCallAsFunctionfunction = false
    public var invokedCallAsFunctionCount = 0
    public var invokedCallAsFunctionParameters: (rules: PasswordRules, preferredLength: Int)?
    public var invokedCallAsFunctionParametersList = [(rules: PasswordRules, preferredLength: Int)]()
    public nonisolated(unsafe) var stubbedCallAsFunctionResult: String?

    public func callAsFunction(rules: PasswordRules, preferredLength: Int) -> String? {
        invokedCallAsFunctionfunction = true
        invokedCallAsFunctionCount += 1
        invokedCallAsFunctionParameters = (rules, preferredLength)
        closureCallAsFunction()
        return stubbedCallAsFunctionResult
    }
}
