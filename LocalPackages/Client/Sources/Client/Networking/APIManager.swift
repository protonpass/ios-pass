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

public final class APIManager: Sendable, APIManagerProtocol {
    public typealias SessionUID = String

    private let logger: Logger
    private let doh: any DoHInterface
    private let themeProvider: any ThemeProvider
    private let userManager: any UserManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let appVer: String
    private var humanHelper: HumanCheckHelper?
    private var forceUpgradeHelper: ForceUpgradeHelper?
    private var allCurrentApiServices = [any APIService]()

    public private(set) var apiService: (any APIService)!
    public let sessionWasInvalidated: PassthroughSubject<SessionUID, Never> = .init()

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

        // TODO: create all apiservices for all current session recorded and set main apiservice
        // also have function to switch main api service when user switch

//        let apiService: PMAPIService
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())

        for credential in authManager.getAllCurrentCredentials() {
            let newApiService = PMAPIService.createAPIService(doh: doh,
                                                              sessionUID: credential.UID,
                                                              challengeParametersProvider: challengeProvider)
            newApiService.authDelegate = authManager
            newApiService.serviceDelegate = self
            allCurrentApiServices.append(newApiService)
            if let activeUserId = userManager.activeUserId, credential.userID == activeUserId {
                apiService = newApiService
            }
        }

        if allCurrentApiServices.isEmpty {
            let newApiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                            challengeParametersProvider: challengeProvider)
            newApiService.authDelegate = authManager
            newApiService.serviceDelegate = self
            allCurrentApiServices.append(newApiService)
            apiService = newApiService
        }

        // This could also be tweaked as we only log 2 phrases as delegates of forceupgradeHelper
        if let appStoreUrl = URL(string: Constants.appStoreUrl) {
            forceUpgradeHelper = .init(config: .mobile(appStoreUrl), responseDelegate: self)
        } else {
            // Should never happen
            let message = "Can not parse App Store URL"
            assertionFailure(message)
            logger.warning(message)
            forceUpgradeHelper = .init(config: .desktop, responseDelegate: self)
        }

//        if let activeUserId = userManager.activeUserId,
//           let credential = authManager.getCredential(userId: activeUserId) {
//            apiService = PMAPIService.createAPIService(doh: doh,
//                                                       sessionUID: credential.sessionID,
//                                                       challengeParametersProvider: challengeProvider)
//        } else {
//            apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
//                                                                     challengeParametersProvider: challengeProvider)
//        }
//        self.apiService = apiService

        humanHelper = HumanCheckHelper(apiService: apiService,
                                       inAppTheme: {
                                           themeProvider.sharedPreferences.unwrapped().theme.inAppTheme
                                       },
                                       clientApp: .pass)

        apiService.humanDelegate = humanHelper

        authManager.setUpDelegate(self)
//        self.apiService.authDelegate = authManager
//        self.apiService.serviceDelegate = self
        (apiService as? PMAPIService)?.loggingDelegate = self
        apiService.forceUpgradeDelegate = forceUpgradeHelper

        setUpCore()
        fetchUnauthSessionIfNeeded()
    }

    public func updateCurrentSession(sessionId: String) {
        guard let service = allCurrentApiServices.first(where: { $0.sessionUID == sessionId }) else {
            return
        }
        apiService = service
//        apiService.setSessionUID(uid: sessionId)
    }

    public func updateCurrentSession(userId: String) async {
        guard let session = authManager.getCredential(userId: userId),
              session.sessionID != apiService.sessionUID,
              let service = allCurrentApiServices.first(where: { $0.sessionUID == session.sessionID }) else {
            return
        }
//        apiService.setSessionUID(uid: session.sessionID)
        apiService = service
    }

    public func createNewApiService() -> any APIService {
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        let newApiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                        challengeParametersProvider: challengeProvider)
        newApiService.authDelegate = authManager
        newApiService.serviceDelegate = self
        allCurrentApiServices.append(newApiService)
        apiService = newApiService
        // TODO: human helper +
        setUpCore()
        fetchUnauthSessionIfNeeded()
        return apiService
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

    func setUpCore() {
        ObservabilityEnv.current.setupWorld(requestPerformer: apiService)
    }

//    static func setUpApiServices(authManager: any AuthManagerProtocol) -> [any APIService] {
//        for credential in authManager.getAllCurrentCredentials() {
//
//        }
//    }

    func fetchUnauthSessionIfNeeded() {
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
        apiService.setSessionUID(uid: "")
        fetchUnauthSessionIfNeeded()
        if isAuthenticatedSession {
            logger.info("Authenticated session is invalidated. Logging out.")
            // swiftlint:disable:next todo
            // TODO: check that this should only log out the user link to this session and not all users
            sessionWasInvalidated.send(sessionUID)
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
        }
    }

    public func credentialsWereUpdated(authCredential: AuthCredential,
                                       credential: Credential,
                                       for sessionUID: String) {
        logger.info("Session credentials are updated")
        guard apiService.sessionUID != sessionUID,
              let service = allCurrentApiServices.first(where: { $0.sessionUID == sessionUID }) else {
            return
        }

        apiService = service
//        if apiService.sessionUID != sessionUID {
//            apiService.setSessionUID(uid: sessionUID)
//        }
//
//        guard let service = allCurrentApiServices.first(where: { $0.sessionUID == sessionId }) else {
//            return
//        }
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

// MARK: - ForceUpgradeResponseDelegate

// TODO: DO we need these logs ?
extension APIManager: ForceUpgradeResponseDelegate {
    public func onQuitButtonPressed() {
        logger.info("Quit force upgrade page")
    }

    public func onUpdateButtonPressed() {
        logger.info("Forced upgrade")
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
