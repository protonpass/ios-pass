//
// ItemWeaknessEvaluator.swift
// Proton Pass - Created on 17/06/2026.
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

import Entities
import PassRustCore

// sourcery: AutoMockable
public protocol ItemWeaknessEvaluatorProtocol: Sendable {
    func evaluate(_ login: LogInItemData, isReused: Bool) -> Set<WeaknessKind>
}

public struct ItemWeaknessEvaluator: ItemWeaknessEvaluatorProtocol {
    private let passwordScorer: any PasswordScorerProtocol
    private let twofaDomainChecker: any TwofaDomainCheckerProtocol

    public init(passwordScorer: any PasswordScorerProtocol = PasswordScorer(),
                twofaDomainChecker: any TwofaDomainCheckerProtocol = TwofaDomainChecker()) {
        self.passwordScorer = passwordScorer
        self.twofaDomainChecker = twofaDomainChecker
    }

    public func evaluate(_ login: LogInItemData, isReused: Bool) -> Set<WeaknessKind> {
        var detected = Set<WeaknessKind>()

        if isReused {
            detected.insert(.reusedPassword)
        }

        if !login.password.isEmpty,
           passwordScorer.checkScore(password: login.password) != .strong {
            detected.insert(.weakPassword)
        }

        if login.totpUri.isEmpty,
           login.passkeys.isEmpty,
           login.urls.contains(where: { twofaDomainChecker.twofaDomainEligible(domain: $0) }) {
            detected.insert(.missing2FA)
        }

        return detected
    }
}
