//
// APIManager.swift
// Proton Pass - Created on 10/07/2024.
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

import Combine
import Core
import Entities
import Factory
import Foundation
import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreCryptoGoInterface
@preconcurrency import ProtonCoreDoh
@preconcurrency import ProtonCoreEnvironment
import ProtonCoreForceUpgrade
import ProtonCoreFoundations
import ProtonCoreHumanVerification
@preconcurrency import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreServices

private struct APIManagerElements {
    let apiService: any APIService
    let humanVerification: any HumanVerifyDelegate
    let isAuthenticated: Bool

    func copy(isAuthenticated: Bool) -> APIManagerElements {
        APIManagerElements(apiService: apiService,
                           humanVerification: humanVerification,
                           isAuthenticated: isAuthenticated)
    }
}

private extension [APIManagerElements] {
    var unauthApiService: (any APIService)? {
        first(where: { !$0.isAuthenticated })?.apiService
    }
}

public final class APIManager: Sendable, APIManagerProtocol {
    private let logger: Logger
    private let doh: any DoHInterface
    private let themeProvider: any ThemeProvider
    private let userManager: any UserManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let appVer: String
    private let forceUpgradeHelper: ForceUpgradeHelper
    private var allCurrentApiServices = [APIManagerElements]()

    public init(authManager: any AuthManagerProtocol,
                userManager: any UserManagerProtocol,
                themeProvider: any ThemeProvider,
                appVersion: String,
                doh: any DoHInterface,
                logManager: any LogManagerProtocol) {
        self.authManager = authManager
        self.userManager = userManager
        self.themeProvider = themeProvider
        appVer = appVersion
        self.doh = doh
        logger = .init(manager: logManager)

        Self.setUpCertificatePinning()

        if let appStoreUrl = URL(string: Constants.appStoreUrl) {
            forceUpgradeHelper = .init(config: .mobile(appStoreUrl))
        } else {
            // Should never happen
            let message = "Can not parse App Store URL"
            assertionFailure(message)
            logger.warning(message)
            forceUpgradeHelper = .init(config: .desktop)
        }

        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        for credential in authManager.getAllCurrentCredentials() {
            let newApiService = PMAPIService.createAPIService(doh: doh,
                                                              sessionUID: credential.UID,
                                                              challengeParametersProvider: challengeProvider)
            newApiService.authDelegate = authManager
            newApiService.serviceDelegate = self
            let humanHelper = createHumanChecker(apiService: newApiService)

            newApiService.humanDelegate = humanHelper
            newApiService.loggingDelegate = self
            newApiService.forceUpgradeDelegate = forceUpgradeHelper
            allCurrentApiServices.append(APIManagerElements(apiService: newApiService,
                                                            humanVerification: humanHelper,
                                                            isAuthenticated: !credential
                                                                .isForUnauthenticatedSession))
        }

        if allCurrentApiServices.isEmpty {
            let newApiService = PMAPIService
                .createAPIServiceWithoutSession(doh: doh, challengeParametersProvider: challengeProvider)
            newApiService.authDelegate = authManager
            newApiService.serviceDelegate = self
            let humanHelper = createHumanChecker(apiService: newApiService)

            newApiService.humanDelegate = humanHelper
            newApiService.loggingDelegate = self
            newApiService.forceUpgradeDelegate = forceUpgradeHelper
            allCurrentApiServices.append(APIManagerElements(apiService: newApiService,
                                                            humanVerification: humanHelper,
                                                            isAuthenticated: false))
            fetchUnauthSessionIfNeeded(apiService: newApiService)
        }

        if let apiService = allCurrentApiServices.first {
            setUpCore(apiService: apiService.apiService)
        }

        authManager.setUpDelegate(self)
    }

    @discardableResult
    public func getUnauthApiService() -> any APIService {
        if let unauthApiService = allCurrentApiServices.unauthApiService {
            return unauthApiService
        }
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        let newApiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                        challengeParametersProvider: challengeProvider)
        newApiService.authDelegate = authManager
        newApiService.serviceDelegate = self

        let humanHelper = createHumanChecker(apiService: newApiService)
        newApiService.humanDelegate = humanHelper
        newApiService.loggingDelegate = self
        newApiService.forceUpgradeDelegate = forceUpgradeHelper
        allCurrentApiServices.append(APIManagerElements(apiService: newApiService,
                                                        humanVerification: humanHelper,
                                                        isAuthenticated: false))

        fetchUnauthSessionIfNeeded(apiService: newApiService)

        return newApiService
    }

    public func getApiService(userId: String) throws -> any APIService {
        if let credentials = authManager.getCredential(userId: userId),
           let service = allCurrentApiServices
           .first(where: { $0.apiService.sessionUID == credentials.sessionID }) {
            return service.apiService
        } else if let unauthApiService = allCurrentApiServices.unauthApiService {
            return unauthApiService
        }

        throw PassError.api(.noApiServiceLinkedToUserId)
    }

    public func reset() {
        // swiftlint:disable:next todo
        // TODO: Should maybe remove all apiservices
        getUnauthApiService()
        if let apiService = allCurrentApiServices.first {
            setUpCore(apiService: apiService.apiService)
        }
    }
}

// MARK: - Utils

private extension APIManager {
    static func setUpCertificatePinning() {
        // Removed trustkit delegate has we don't do anything with it and it is optional
        TrustKitWrapper.setUp()
        let trustKit = TrustKitWrapper.current
        PMAPIService.trustKit = trustKit
        PMAPIService.noTrustKit = trustKit == nil
    }

    func setUpCore(apiService: any APIService) {
        ObservabilityEnv.current.setupWorld(requestPerformer: apiService)
    }

    func fetchUnauthSessionIfNeeded(apiService: any APIService) {
        apiService.acquireSessionIfNeeded { [weak self] result in
            guard let self else {
                return
            }
            switch result {
            case let .success(value):
                switch value {
                case let .sessionAlreadyPresent(session), let .sessionFetchedAndAvailable(session):
                    logger.trace("UnauthSession: \(session)")
                case .sessionUnavailableAndNotFetched:
                    logger.trace("session Unavailable And Not Fetched")
                }
            // session was already available, or servers were
            // reached but returned 4xx/5xx.
            // In both cases we're done here
            case let .failure(error):
                // servers not reachable
                logger.error(error)
            }
        }
    }
}

// MARK: - AuthHelperDelegate

extension APIManager: AuthHelperDelegate {
    public func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        allCurrentApiServices.removeAll { $0.apiService.sessionUID == sessionUID }
        if allCurrentApiServices.isEmpty {
            getUnauthApiService()
        }

        if isAuthenticatedSession {
            logger.info("Authenticated session is invalidated. Logging out.")
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
        }
    }

    public func credentialsWereUpdated(authCredential: AuthCredential,
                                       credential: Credential,
                                       for sessionUID: String) {
        allCurrentApiServices = allCurrentApiServices.map { element in
            guard element.apiService.sessionUID == sessionUID else {
                return element
            }

            return element.copy(isAuthenticated: !authCredential.isForUnauthenticatedSession)
        }

        logger.info("Session credentials are updated")
    }

    func createHumanChecker(apiService: any APIService) -> HumanCheckHelper {
        HumanCheckHelper(apiService: apiService,
                         inAppTheme: { [weak self] in
                             guard let self else {
                                 return .matchSystem
                             }
                             return themeProvider.sharedPreferences.unwrapped().theme
                                 .inAppTheme
                         }, clientApp: .pass)
    }
}

// MARK: - APIServiceDelegate

extension APIManager: APIServiceDelegate {
    public var appVersion: String { appVer }
    public var userAgent: String? { UserAgent.default.ua }
    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var additionalHeaders: [String: String]? { nil }

    public func onDohTroubleshot() {}

    public func onUpdate(serverTime: Int64) {
        CryptoGo.CryptoUpdateTime(serverTime)
    }

    public func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        true
    }
}

// MARK: - APIServiceLoggingDelegate

extension APIManager: APIServiceLoggingDelegate {
    public func accessTokenRefreshDidStart(for sessionID: String,
                                           sessionType: APISessionTypeForLogging) {
        logger.info("Access token refresh did start for \(sessionType) session \(sessionID)")
    }

    public func accessTokenRefreshDidSucceed(for sessionID: String,
                                             sessionType: APISessionTypeForLogging,
                                             reason: APIServiceAccessTokenRefreshSuccessReasonForLogging) {
        logger.info("""
        Access token refresh did succeed for \(sessionType) session \(sessionID)
        with reason \(reason)
        """)
    }

    public func accessTokenRefreshDidFail(for sessionID: String,
                                          sessionType: APISessionTypeForLogging,
                                          error: APIServiceAccessTokenRefreshErrorForLogging) {
        logger.error(message: "Access token refresh did fail for \(sessionType) session \(sessionID)",
                     error: error)
    }
}
