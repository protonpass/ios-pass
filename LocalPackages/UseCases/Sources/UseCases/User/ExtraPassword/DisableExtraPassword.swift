//
// DisableExtraPassword.swift
// Proton Pass - Created on 07/06/2024.
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
import Foundation

public protocol DisableExtraPasswordUseCase: Sendable {
    func execute(username: String,
                 password: String) async throws -> DisableExtraPasswordResult
}

public extension DisableExtraPasswordUseCase {
    func callAsFunction(username: String,
                        password: String) async throws -> DisableExtraPasswordResult {
        try await execute(username: username, password: password)
    }
}

public final class DisableExtraPassword: Sendable, DisableExtraPasswordUseCase {
    private let repository: any ExtraPasswordRepositoryProtocol
    private let verifyExtraPassword: any VerifyExtraPasswordUseCase

    public init(repository: any ExtraPasswordRepositoryProtocol,
                verifyExtraPassword: any VerifyExtraPasswordUseCase) {
        self.repository = repository
        self.verifyExtraPassword = verifyExtraPassword
    }

    public func execute(username: String,
                        password: String) async throws -> DisableExtraPasswordResult {
        let verificationResult = try await verifyExtraPassword(repository: repository,
                                                               username: username,
                                                               password: password)
        guard verificationResult.isSuccessful else {
            return verificationResult
        }

        try await repository.disableExtraPassword()
        return .successful
    }
}
