//
//
// SetUpEmailAndUsername.swift
// Proton Pass - Created on 14/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Client
import Entities

public protocol SetUpEmailAndUsernameUseCase: Sendable {
    func execute(container: any UsernameEmailContainer) -> (email: String, username: String)
}

public extension SetUpEmailAndUsernameUseCase {
    func callAsFunction(container: any UsernameEmailContainer) -> (email: String, username: String) {
        execute(container: container)
    }
}

public final class SetUpEmailAndUsername: SetUpEmailAndUsernameUseCase {
    private let featureFlags: any GetFeatureFlagStatusUseCase
    private let emailValidator: any ValidateEmailUseCase

    public init(featureFlags: any GetFeatureFlagStatusUseCase,
                emailValidator: any ValidateEmailUseCase) {
        self.featureFlags = featureFlags
        self.emailValidator = emailValidator
    }

    public func execute(container: any UsernameEmailContainer) -> (email: String, username: String) {
        guard featureFlags(with: FeatureFlagType.passUsernameSplit) else {
            return (container.email, "")
        }

        return !container.username.isEmpty ?
            (container.email, container.username) : emailValidator(email: container.email) ?
            (container.email, "") : ("", container.email)
    }
}
