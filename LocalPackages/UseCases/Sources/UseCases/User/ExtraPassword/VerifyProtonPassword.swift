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
@preconcurrency import ProtonCoreCryptoGoInterface
@preconcurrency import ProtonCoreDoh
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
    private let userManager: any UserManagerProtocol
    private let doh: any DoHInterface
    private let appVer: String

    // Required by `AuthDelegate`
    // swiftlint:disable:next identifier_name
    public var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?

    private var apiService: (any APIService)?

    public init(userManager: any UserManagerProtocol,
                doh: any DoHInterface,
                appVer: String) {
        self.userManager = userManager
        self.doh = doh
        self.appVer = appVer
    }

    public func execute(_ password: String) async throws -> Bool {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let authenticator = Authenticator(api: makeApiService())
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

private extension VerifyProtonPassword {
    func makeApiService() -> any APIService {
        if let apiService {
            return apiService
        }
        // Create an unauth api service on the fly otherwise wrong verifications
        // would expire the current session (log the user out)
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        let apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                     challengeParametersProvider: challengeProvider)
        apiService.serviceDelegate = self
        apiService.authDelegate = self
        self.apiService = apiService
        return apiService
    }
}

// MARK: APIServiceDelegate

extension VerifyProtonPassword: APIServiceDelegate {
    public var appVersion: String { appVer }
    public var userAgent: String? { UserAgent.default.ua }
    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var additionalHeaders: [String: String]? { nil }

    public func onDohTroubleshot() {}

    public func onUpdate(serverTime: Int64) {
        CryptoGo.CryptoUpdateTime(serverTime)
    }

    public func isReachable() -> Bool {
        true
    }
}

// MARK: AuthDelegate

/// Do nothing, just to make the `APIService` happy because it expectes an `AuthDelegate`
extension VerifyProtonPassword: AuthDelegate {
    public func authCredential(sessionUID: String) -> AuthCredential? { nil }
    public func credential(sessionUID: String) -> Credential? { nil }
    public func onUpdate(credential: Credential, sessionUID: String) {}
    public func onSessionObtaining(credential: Credential) {}
    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {}
    public func onAuthenticatedSessionInvalidated(sessionUID: String) {}
    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {}
}
