//
// VerifyProtonPassword.swift
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
import Entities
import Foundation
import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreCryptoGoInterface
import ProtonCoreDoh
import ProtonCoreFoundations
import ProtonCoreNetworking
import ProtonCoreServices

public protocol VerifyProtonPasswordUseCase: Sendable {
    func execute(_ password: String) async throws -> Bool
}

public extension VerifyProtonPasswordUseCase {
    func callAsFunction(_ password: String) async throws -> Bool {
        try await execute(password)
    }
}

public final class VerifyProtonPassword: Sendable, VerifyProtonPasswordUseCase {
    private let userDataProvider: any UserDataProvider
    private let apiService: any APIService

    public init(userDataProvider: any UserDataProvider,
                apiService: any APIService) {
        self.userDataProvider = userDataProvider
        self.apiService = apiService
    }

    public func execute(_ password: String) async throws -> Bool {
        guard let userData = userDataProvider.getUserData() else {
            throw PassError.noUserData
        }

        let authenticator = Authenticator(api: apiService)
        return try await withCheckedThrowingContinuation { continuation in
            authenticator.authenticate(username: userData.credential.userName,
                                       password: password,
                                       challenge: nil) { result in
                switch result {
                case .success:
                    continuation.resume(returning: true)
                case let .failure(error):
                    switch error {
                    /// Upon testing`wrongPassword` case is not returned by this method but just in case
                    case .wrongPassword:
                        continuation.resume(returning: false)
                    case let .networkingError(networkError):
                        if networkError.httpCode == 422,
                           networkError.responseCode == 8_002 {
                            continuation.resume(returning: false)
                        } else {
                            continuation.resume(throwing: networkError)
                        }
                    default:
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
