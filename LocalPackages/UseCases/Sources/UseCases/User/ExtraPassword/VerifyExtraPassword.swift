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
import Entities
import Foundation

public enum ExtraPasswordVerificationResult: Sendable {
    case successful
    case wrongPassword
    case tooManyAttempts
}

public protocol VerifyExtraPasswordUseCase: Sendable {
    func execute(_ password: String) async throws -> ExtraPasswordVerificationResult
}

public extension VerifyExtraPasswordUseCase {
    func callAsFunction(_ password: String) async throws -> ExtraPasswordVerificationResult {
        try await execute(password)
    }
}

public actor VerifyExtraPassword: Sendable, VerifyExtraPasswordUseCase {
    private let repository: any ExtraPasswordRepositoryProtocol
    private var authData: SrpAuthenticationData?

    public init(repository: any ExtraPasswordRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(_ password: String) async throws -> ExtraPasswordVerificationResult {
        // Step 1: initiate the process
        let authData = try await getAuthData()

        // Step 2: cryptographic voodoo
        let validationData = SrpValidationData(clientEphemeral: "",
                                               clientProof: "",
                                               srpSessionID: "")

        // Step 3: validation
        do {
            try await repository.validateSrpAuthentication(validationData)
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

private extension VerifyExtraPassword {
    func getAuthData() async throws -> SrpAuthenticationData {
        if let authData {
            return authData
        }
        let authData = try await repository.initiateSrpAuthentication()
        self.authData = authData
        return authData
    }
}
