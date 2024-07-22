//
// EnableExtraPassword.swift
// Proton Pass - Created on 30/05/2024.
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
import Core
import Entities
import Foundation
import ProtonCoreAuthenticationKeyGeneration
import ProtonCoreCrypto
import ProtonCoreUtilities

public protocol EnableExtraPasswordUseCase: Sendable {
    func execute(userId: String, password: String) async throws
}

public extension EnableExtraPasswordUseCase {
    func callAsFunction(userId: String,
                        password: String) async throws {
        try await execute(userId: userId, password: password)
    }
}

public final class EnableExtraPassword: Sendable, EnableExtraPasswordUseCase {
    private let repository: any ExtraPasswordRepositoryProtocol

    public init(repository: any ExtraPasswordRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(userId: String,
                        password: String) async throws {
        // Step 1: get modulus from the BE
        let modulus = try await repository.getModulus(userId: userId)

        // Step 2: hash the password from the modulus
        guard let salt = try SrpRandomBits(PasswordSaltSize.login.IntBits) else {
            throw PassError.extraPassword(.failedToGenerateSalt)
        }

        guard let auth = try SrpAuthForVerifier(password, modulus.modulus, salt) else {
            throw PassError.extraPassword(.failedToHashPassword)
        }

        let verifier = try auth.generateVerifier(Constants.ExtraPassword.srpBitLength)
        let userSrp = PassUserSrp(modulusId: modulus.modulusID,
                                  verifier: verifier.encodeBase64(),
                                  salt: salt.encodeBase64())

        // Step 3: finalize the SRP process and enable extra password
        try await repository.enableExtraPassword(userId: userId, userSrp: userSrp)
    }
}
