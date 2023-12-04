//
//
// GetPasswordStrength.swift
// Proton Pass - Created on 27/11/2023.
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
//

import Entities

@preconcurrency import PassRustCore

public protocol GetPasswordStrengthUseCase: Sendable {
    func execute(password: String) -> PasswordStrength
}

public extension GetPasswordStrengthUseCase {
    func callAsFunction(password: String) -> PasswordStrength {
        execute(password: password)
    }
}

public final class GetPasswordStrength: GetPasswordStrengthUseCase {
    private let passwordScorer: any PasswordScorerProtocol

    public init(passwordScorer: any PasswordScorerProtocol = PasswordScorer()) {
        self.passwordScorer = passwordScorer
    }

    public func execute(password: String) -> PasswordStrength {
        switch passwordScorer.checkScore(password: password) {
        case .dangerous, .veryDangerous:
            .vulnerable
        case .veryWeak, .weak:
            .weak
        default:
            .strong
        }
    }
}
