//
//
// CreateApiService.swift
// Proton Pass - Created on 03/07/2024.
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
import Foundation
@preconcurrency import ProtonCoreCryptoGoInterface
@preconcurrency import ProtonCoreDoh
import ProtonCoreFoundations
@preconcurrency import ProtonCoreNetworking
import ProtonCoreServices

public protocol CreateApiServiceUseCase: Sendable {
    func execute() -> any APIService
}

public extension CreateApiServiceUseCase {
    func callAsFunction() -> any APIService {
        execute()
    }
}

public final class CreateApiService: CreateApiServiceUseCase {
    private let doh: any DoHInterface
    private let appVer: String
    private let protonCoreUserAgent: UserAgent
    private let cryptoGo: any CryptoGoMethods
    private let authManager: any AuthManagerProtocol

    // Required by `AuthDelegate`
    // swiftlint:disable:next identifier_name
    public var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?

    public init(doh: any DoHInterface,
                appVer: String,
                protonCoreUserAgent: UserAgent = .default,
                cryptoGo: any CryptoGoMethods = CryptoGo,
                authManager: any AuthManagerProtocol) {
        self.doh = doh
        self.protonCoreUserAgent = protonCoreUserAgent
        self.appVer = appVer
        self.cryptoGo = cryptoGo
        self.authManager = authManager
    }

    public func execute() -> any APIService {
        // Create an unauth api service on the fly otherwise wrong verifications
        // would expire the current session (log the user out)
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        let apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                     challengeParametersProvider: challengeProvider)
        apiService.serviceDelegate = self
        apiService.authDelegate = self
        return apiService
    }
}

// MARK: APIServiceDelegate

extension CreateApiService: APIServiceDelegate {
    public var appVersion: String { appVer }
    public var userAgent: String? { protonCoreUserAgent.ua }
    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var additionalHeaders: [String: String]? { nil }

    public func onDohTroubleshot() {}

    public func onUpdate(serverTime: Int64) {
        cryptoGo.CryptoUpdateTime(serverTime)
    }

    public func isReachable() -> Bool {
        true
    }
}

// MARK: AuthDelegate

extension CreateApiService: AuthDelegate {
    public func authCredential(sessionUID: String) -> AuthCredential? {
        authManager.authCredential(sessionUID: sessionUID)
    }

    public func credential(sessionUID: String) -> Credential? {
        authManager.credential(sessionUID: sessionUID)
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        // As we use the main authManager this updates this update the main apiService with theses new credentials
        // through apiManager as authManager is a a delegate off it
        // The function in authManager that update the main apiService is **credentialsWereUpdated**
        // This should be kept in mind as it can have some impact on the calls made by the main apiservice
        authManager.onUpdate(credential: credential, sessionUID: sessionUID)
    }

    public func onSessionObtaining(credential: Credential) {
        // As we use the main authManager this updates this update the main apiMervice with theses new credentials
        // through apiManager as authManager is a a delegate off it
        // The function in authManager that update the main apiService is **credentialsWereUpdated**
        // This should be kept in mind as it can have some impact on the calls made by the main apiservice
        authManager.onSessionObtaining(credential: credential)
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {}
    public func onAuthenticatedSessionInvalidated(sessionUID: String) {}
    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {}
}
