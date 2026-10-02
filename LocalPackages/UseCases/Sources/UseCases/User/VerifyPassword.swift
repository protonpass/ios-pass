//
// VerifyPassword.swift
// Proton Pass - Created on 11/08/2026.
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

import Client
import ProtonCorePasswordRequest

public protocol VerifyPasswordUseCase: Sendable {
    func callAsFunction(_ password: String) async throws
}

public struct VerifyPassword: VerifyPasswordUseCase {
    private let userManager: any UserManagerProtocol
    private let apiManager: any APIManagerProtocol

    public init(userManager: any UserManagerProtocol,
                apiManager: any APIManagerProtocol) {
        self.userManager = userManager
        self.apiManager = apiManager
    }

    public func callAsFunction(_ password: String) async throws {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let apiService = try apiManager.getApiService(userId: userData.user.ID)
        let verifier = PasswordVerifier(apiService: apiService,
                                        username: userData.credential.userName,
                                        endpoint: UnlockEndpoint(),
                                        missingScopeMode: .default)

        try await withCheckedThrowingContinuation { continuation in
            verifier.fetchAuthInfo { authInfoResult in
                switch authInfoResult {
                case let .success(authInfo):
                    verifier.verifyPassword(password: password,
                                            authInfo: authInfo) { verificationResult in
                        switch verificationResult {
                        case .success:
                            continuation.resume()

                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
