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

// import Entities
import Foundation

// import ProtonCoreAuthentication
// import ProtonCoreChallenge
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

// private extension VerifyProtonPassword {
//    func makeApiService() -> any APIService {
//        if let apiService {
//            return apiService
//        }
//        // Create an unauth api service on the fly otherwise wrong verifications
//        // would expire the current session (log the user out)
//        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
//                                                                          challenge: .init())
//        let apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
//                                                                     challengeParametersProvider: challengeProvider)
//        apiService.serviceDelegate = self
//        apiService.authDelegate = self
//        self.apiService = apiService
//        return apiService
//    }
// }

//// MARK: APIServiceDelegate
//
// extension VerifyProtonPassword: APIServiceDelegate {
//    public var appVersion: String { appVer }
//    public var userAgent: String? { UserAgent.default.ua }
//    public var locale: String { Locale.autoupdatingCurrent.identifier }
//    public var additionalHeaders: [String: String]? { nil }
//
//    public func onDohTroubleshot() {}
//
//    public func onUpdate(serverTime: Int64) {
//        CryptoGo.CryptoUpdateTime(serverTime)
//    }
//
//    public func isReachable() -> Bool {
//        true
//    }
// }
//
//// MARK: AuthDelegate
//
///// Do nothing, just to make the `APIService` happy because it expectes an `AuthDelegate`
// extension VerifyProtonPassword: AuthDelegate {
//    public func authCredential(sessionUID: String) -> AuthCredential? { nil }
//    public func credential(sessionUID: String) -> Credential? { nil }
//    public func onUpdate(credential: Credential, sessionUID: String) {}
//    public func onSessionObtaining(credential: Credential) {}
//    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
//                                                    password: String?,
//                                                    salt: String?,
//                                                    privateKey: String?) {}
//    public func onAuthenticatedSessionInvalidated(sessionUID: String) {}
//    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {}
// }

public final class CreateApiService: CreateApiServiceUseCase {
    private let doh: any DoHInterface
    private let appVer: String
    private let protonCoreUserAgent: UserAgent
    private let cryptoGo: any CryptoGoMethods
    private let authManager: any AuthManagerProtocol
//    private var credentials = [String: Credential]()

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
    public var userAgent: String? { protonCoreUserAgent.ua /* UserAgent.default.ua */ /*  */ }
    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var additionalHeaders: [String: String]? { nil }

    public func onDohTroubleshot() {}

    public func onUpdate(serverTime: Int64) {
//        CryptoGo.CryptoUpdateTime(serverTime)
        cryptoGo.CryptoUpdateTime(serverTime)
    }

    public func isReachable() -> Bool {
        true
    }
}

//
// private let userManager: any UserManagerProtocol
// private let doh: any DoHInterface
// private let appVer: String
//
//// Required by `AuthDelegate`
//// swiftlint:disable:next identifier_name
// public var authSessionInvalidatedDelegateForLoginAndSignup: (any AuthSessionInvalidatedDelegate)?
//
// private var apiService: (any APIService)?
//
// public init(userManager: any UserManagerProtocol,
//            doh: any DoHInterface,
//            appVer: String) {
//    self.userManager = userManager
//    self.doh = doh
//    self.appVer = appVer
// }

//
// private extension VerifyProtonPassword {
//    func makeApiService() -> any APIService {
//        if let apiService {
//            return apiService
//        }
//        // Create an unauth api service on the fly otherwise wrong verifications
//        // would expire the current session (log the user out)
//        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
//                                                                          challenge: .init())
//        let apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
//                                                                     challengeParametersProvider: challengeProvider)
//        apiService.serviceDelegate = self
//        apiService.authDelegate = self
//        self.apiService = apiService
//        return apiService
//    }
// }
//
//
//// MARK: AuthDelegate
//
///// Do nothing, just to make the `APIService` happy because it expectes an `AuthDelegate`
extension CreateApiService: AuthDelegate {
    public func authCredential(sessionUID: String) -> AuthCredential? {
//        guard let credential = credentials[sessionUID] else {
//            return nil
//        }
//
//        print("woot authCredential in: \(credential.UID)")
//
//        return AuthCredential(credential)

        authManager.authCredential(sessionUID: sessionUID)
    }

    public func credential(sessionUID: String) -> Credential? {
//        print("woot credential in: \(credentials[sessionUID]?.UID)")
//
//        return credentials[sessionUID]
        authManager.credential(sessionUID: sessionUID)
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
//        print("woot on update in: \(credential.UID), id: \(sessionUID)")
//
//        credentials[sessionUID] = credential
        authManager.onUpdate(credential: credential, sessionUID: sessionUID)
    }

    public func onSessionObtaining(credential: Credential) {
//        print("woot onSessionObtaining in: \(credential.UID)")
//
//        credentials[credential.UID] = credential
        authManager.onSessionObtaining(credential: credential)
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {}
    public func onAuthenticatedSessionInvalidated(sessionUID: String) {}
    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {}
}
