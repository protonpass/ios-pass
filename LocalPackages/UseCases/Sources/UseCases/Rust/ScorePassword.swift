//
// ScorePassword.swift
// Proton Pass - Created on 26/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import PassRustCore

public protocol ScorePasswordUseCase: Sendable {
    func callAsFunction(_ password: String) -> Entities.PasswordScore
}

private extension PassRustCore.PasswordScore {
    var toNativeStrength: Entities.PasswordStrength {
        switch self {
        case .vulnerable: .vulnerable
        case .weak: .weak
        case .strong: .strong
        }
    }
}

public struct ScorePassword: ScorePasswordUseCase {
    private let scorer: any PasswordScorerProtocol

    public init(scorer: any PasswordScorerProtocol = PasswordScorer()) {
        self.scorer = scorer
    }

    public func callAsFunction(_ password: String) -> Entities.PasswordScore {
        let score = scorer.scorePassword(password: password)
        return .init(strength: score.passwordScore.toNativeStrength,
                     penalties: score.penalties.map(\.toNativePenalty))
    }
}

private extension PassRustCore.PasswordPenalty {
    var toNativePenalty: Entities.PasswordPenalty {
        switch self {
        case .noLowercase: .noLowercase
        case .noUppercase: .noUppercase
        case .noNumbers: .noNumbers
        case .noSymbols: .noSymbols
        case .short: .short
        case .consecutive: .consecutive
        case .progressive: .progressive
        case .containsCommonPassword: .containsCommonPassword
        }
    }
}
