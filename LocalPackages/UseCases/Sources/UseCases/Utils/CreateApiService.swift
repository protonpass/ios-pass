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
    func execute(sessionId: String?) -> any APIService
}

public extension CreateApiServiceUseCase {
    func callAsFunction() -> any APIService {
        execute()
    }

    func callAsFunction(sessionId: String?) -> any APIService {
        execute(sessionId: sessionId)
    }
}

public final class CreateApiService: @unchecked Sendable, CreateApiServiceUseCase {
    private let doh: any DoHInterface
    private let appVer: String
    private let protonCoreUserAgent: UserAgent
    private let cryptoGo: any CryptoGoMethods
    private let serialAccessQueue = DispatchQueue(label: "me.pass.createapiservice_queue")
    private var credential: Credential?

    // Required by `AuthDelegate`
    // swiftlint:disable:next identifier_name
    public var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?

    public init(doh: any DoHInterface,
                appVer: String,
                protonCoreUserAgent: UserAgent = .default,
                cryptoGo: any CryptoGoMethods = CryptoGo) {
        self.doh = doh
        self.protonCoreUserAgent = protonCoreUserAgent
        self.appVer = appVer
        self.cryptoGo = cryptoGo
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

    public func execute(sessionId: String?) -> any APIService {
        // Create an unauth api service on the fly otherwise wrong verifications
        // would expire the current session (log the user out)
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        var apiService: any APIService = if let sessionId {
            PMAPIService.createAPIService(doh: doh,
                                          sessionUID: sessionId,
                                          challengeParametersProvider: challengeProvider)
        } else {
            PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                        challengeParametersProvider: challengeProvider)
        }

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
        serialAccessQueue.sync {
            guard let credential, credential.UID == sessionUID else {
                return nil
            }
            return AuthCredential(credential)
        }
    }

    public func credential(sessionUID: String) -> Credential? {
        serialAccessQueue.sync {
            guard let credential, credential.UID == sessionUID else {
                return nil
            }
            return credential
        }
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        serialAccessQueue.sync {
            guard credential.UID == sessionUID else {
                return
            }
            self.credential = credential
        }
    }

    public func onSessionObtaining(credential: Credential) {
        serialAccessQueue.sync {
            self.credential = credential
        }
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {}
    public func onAuthenticatedSessionInvalidated(sessionUID: String) {}
    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {}
}
