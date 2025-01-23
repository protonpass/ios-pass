//
// VerifyExtraPassword.swift
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
import Core
import Entities
import Foundation
@preconcurrency import ProtonCoreCryptoGoInterface

public protocol VerifyExtraPasswordUseCase: Sendable {
    func execute(repository: any ExtraPasswordRepositoryProtocol,
                 userId: String,
                 username: String,
                 password: String) async throws -> ExtraPasswordVerificationResult
}

public extension VerifyExtraPasswordUseCase {
    func callAsFunction(repository: any ExtraPasswordRepositoryProtocol,
                        userId: String,
                        username: String,
                        password: String) async throws -> ExtraPasswordVerificationResult {
        try await execute(repository: repository, userId: userId, username: username, password: password)
    }
}

public actor VerifyExtraPassword: VerifyExtraPasswordUseCase {
    public init() {}

    public func execute(repository: any ExtraPasswordRepositoryProtocol,
                        userId: String,
                        username: String,
                        password: String) async throws -> ExtraPasswordVerificationResult {
        // Step 1: initiate the process
        let authData = try await repository.initiateSrpAuthentication(userId: userId)

        // Step 2: cryptographic voodoo
        guard let auth = CryptoGo.SrpAuth(authData.version,
                                          username,
                                          password.data(using: .utf8),
                                          authData.srpSalt,
                                          authData.modulus,
                                          authData.serverEphemeral) else {
            throw PassError.extraPassword(.failedToGenerateSrpAuth)
        }

        let srpClient = try auth.generateProofs(Constants.ExtraPassword.srpBitLength)
        guard let ephemeral = srpClient.clientEphemeral?.encodeBase64(),
              let proof = srpClient.clientProof?.encodeBase64() else {
            throw PassError.extraPassword(.emptySrpClientAuth)
        }

        let validationData = SrpValidationData(clientEphemeral: ephemeral,
                                               clientProof: proof,
                                               srpSessionID: authData.srpSessionID)

        // Step 3: validation
        do {
            try await repository.validateSrpAuthentication(userId: userId, data: validationData)
            return .successful
        } catch {
            if let apiError = error.asPassApiError {
                switch apiError {
                case .notAllowed:
                    return .wrongPassword
                case .tooManyWrongAttempts:
                    return .tooManyAttempts
                default:
                    break
                }
            }
            throw error
        }
    }
}
