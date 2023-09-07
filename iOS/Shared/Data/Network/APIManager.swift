//
// APIManager.swift
// Proton Pass - Created on 08/02/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Client
import Combine
import Core
import CryptoKit
import Factory
import Foundation
import ProtonCoreAuthentication
import ProtonCoreChallenge
import ProtonCoreCryptoGoInterface
import ProtonCoreEnvironment
import ProtonCoreForceUpgrade
import ProtonCoreFoundations
import ProtonCoreHumanVerification
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreObservability
import ProtonCoreServices
import UIKit

protocol APIManagerDelegate: AnyObject {
    func appLoggedOutBecauseSessionWasInvalidated()
}

public protocol APIManagerProtocol {
    var userData: UserData? { get }
    var apiService: APIService { get }
}

final class APIManager: APIManagerProtocol {
    private let logger = resolve(\SharedToolingContainer.logger)
    private let appVer = resolve(\SharedToolingContainer.appVersion)
    private let appData = resolve(\SharedDataContainer.appData)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let trustKitDelegate: TrustKitDelegate

    private(set) var apiService: APIService
    private(set) var authHelper: AuthHelper
    private(set) var forceUpgradeHelper: ForceUpgradeHelper?
    private(set) var humanHelper: HumanCheckHelper?

    // Logout issue mitigation
    @AppStorage("lastSuccessfulRefreshTimestamp", store: kSharedUserDefaults)
    private var lastSuccessfulRefreshTimestamp: TimeInterval?
    private var ignoredRefreshFailure = false

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: APIManagerDelegate?

    var userData: UserData? {
        appData.userData
    }

    init() {
        let trustKitDelegate = PassTrustKitDelegate()
        APIManager.setUpCertificatePinning(trustKitDelegate: trustKitDelegate)
        self.trustKitDelegate = trustKitDelegate

        let doh = ProtonPassDoH()
        let apiService: PMAPIService
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        if let credential = appData.userData?.credential ?? appData.unauthSessionCredentials {
            apiService = PMAPIService.createAPIService(doh: doh,
                                                       sessionUID: credential.sessionID,
                                                       challengeParametersProvider: challengeProvider)
            authHelper = AuthHelper(authCredential: credential)
        } else {
            apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                     challengeParametersProvider: challengeProvider)
            authHelper = AuthHelper()
        }
        self.apiService = apiService
        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        self.apiService.authDelegate = authHelper
        self.apiService.serviceDelegate = self
        apiService.loggingDelegate = self

        humanHelper = HumanCheckHelper(apiService: apiService,
                                       inAppTheme: { [weak self] in
                                           self?.preferences.theme.inAppTheme ?? .matchSystem
                                       },
                                       clientApp: .pass)
        apiService.humanDelegate = humanHelper

        if let appStoreUrl = URL(string: Constants.appStoreUrl) {
            forceUpgradeHelper = .init(config: .mobile(appStoreUrl), responseDelegate: self)
        } else {
            // Should never happen
            let message = "Can not parse App Store URL"
            assertionFailure(message)
            logger.warning(message)
            forceUpgradeHelper = .init(config: .desktop, responseDelegate: self)
        }

        apiService.forceUpgradeDelegate = forceUpgradeHelper

        setUpCore()
        fetchUnauthSessionIfNeeded()
        useNewTokensWhenAppBackToForegound()
    }

    func sessionIsAvailable(authCredential: AuthCredential, scopes: Scopes) {
        apiService.setSessionUID(uid: authCredential.sessionID)
        authHelper.onSessionObtaining(credential: Credential(authCredential, scopes: scopes))
    }

    func clearCredentials() {
        appData.unauthSessionCredentials = nil
        apiService.setSessionUID(uid: "")
        // destroying and recreating AuthHelper to clear its cache
        authHelper = AuthHelper()
        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        apiService.authDelegate = authHelper
    }

    private static func setUpCertificatePinning(trustKitDelegate: TrustKitDelegate) {
        TrustKitWrapper.setUp(delegate: trustKitDelegate)
        PMAPIService.noTrustKit = false
        PMAPIService.trustKit = TrustKitWrapper.current
    }

    private func setUpCore() {
        ObservabilityEnv.current.setupWorld(requestPerformer: apiService)
    }

    private func fetchUnauthSessionIfNeeded() {
        apiService.acquireSessionIfNeeded { result in
            switch result {
            case .success:
                // session was already available, or servers were
                // reached but returned 4xx/5xx.
                // In both cases we're done here
                break
            case let .failure(error):
                // servers not reachable
                self.logger.error(error)
            }
        }
    }

    // UserData with new access token & refresh token can be updated from AutoFill extension
    // Update the session of AuthHelper here to take the new tokens into account
    // Otherwise old token are used and user would be logged out
    private func useNewTokensWhenAppBackToForegound() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let userData = self?.appData.userData else { return }
                self?.authHelper.onSessionObtaining(credential: userData.getCredential)
            }
            .store(in: &cancellables)
    }

    // Create a new instance of UserData with everything copied except credential
    private func update(userData: UserData, authCredential: AuthCredential) {
        let updatedUserData = UserData(credential: authCredential,
                                       user: userData.user,
                                       salts: userData.salts,
                                       passphrases: userData.passphrases,
                                       addresses: userData.addresses,
                                       scopes: userData.scopes)
        appData.userData = updatedUserData
        appData.unauthSessionCredentials = nil
    }

    /// Ignore when last successful refresh happened less than 24h
    private func shouldIgnoreFailure() -> Bool {
        guard let lastSuccessfulRefreshTimestamp, !ignoredRefreshFailure else { return false }
        let lastSuccessfulRefreshDate = Date(timeIntervalSince1970: lastSuccessfulRefreshTimestamp)
        let days = Calendar.current.numberOfDaysBetween(lastSuccessfulRefreshDate, and: .now)
        return days == 0
    }
}

// MARK: - AuthHelperDelegate

extension APIManager: AuthHelperDelegate {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        clearCredentials()
        if isAuthenticatedSession {
            if shouldIgnoreFailure() {
                logger.debug("Authenticated session is invalidated. Ignore failure.")
                ignoredRefreshFailure = true
            } else {
                logger.info("Authenticated session is invalidated. Logging out.")
                appData.userData = nil
                delegate?.appLoggedOutBecauseSessionWasInvalidated()
            }
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
            fetchUnauthSessionIfNeeded()
        }
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String) {
        logger.info("Session credentials are updated")
        if let userData = appData.userData {
            update(userData: userData, authCredential: authCredential)
            lastSuccessfulRefreshTimestamp = Date.now.timeIntervalSince1970
        } else {
            appData.unauthSessionCredentials = authCredential
        }
    }
}

// MARK: - APIServiceDelegate

extension APIManager: APIServiceDelegate {
    var appVersion: String { appVer }
    var userAgent: String? { UserAgent.default.ua }
    var locale: String { Locale.autoupdatingCurrent.identifier }
    var additionalHeaders: [String: String]? { nil }

    func onDohTroubleshot() {}

    func onUpdate(serverTime: Int64) {
        CryptoGo.CryptoUpdateTime(serverTime)
    }

    func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        true
    }
}

// MARK: - ForceUpgradeResponseDelegate

extension APIManager: ForceUpgradeResponseDelegate {
    func onQuitButtonPressed() {
        logger.info("Quit force upgrade page")
    }

    func onUpdateButtonPressed() {
        logger.info("Forced upgrade")
    }
}

// MARK: - APIServiceLoggingDelegate

extension APIManager: APIServiceLoggingDelegate {
    func accessTokenRefreshDidStart(for sessionID: String,
                                    sessionType: APISessionTypeForLogging) {
        logger.info("Access token refresh did start for \(sessionType) session \(sessionID)")
    }

    func accessTokenRefreshDidSucceed(for sessionID: String,
                                      sessionType: APISessionTypeForLogging,
                                      reason: APIServiceAccessTokenRefreshSuccessReasonForLogging) {
        logger.info("""
        Access token refresh did succeed for \(sessionType) session \(sessionID)
        with reason \(reason)
        """)
    }

    func accessTokenRefreshDidFail(for sessionID: String,
                                   sessionType: APISessionTypeForLogging,
                                   error: APIServiceAccessTokenRefreshErrorForLogging) {
        logger.error(message: "Access token refresh did fail for \(sessionType) session \(sessionID)",
                     error: error)
    }
}

// MARK: - TrustKitDelegate

private class PassTrustKitDelegate: TrustKitDelegate {
    let logger = resolve(\SharedToolingContainer.logger)

    init() {}

    func onTrustKitValidationError(_ error: TrustKitError) {
        // just logging right now
        switch error {
        case .failed:
            logger.error("Trust kit validation failed")
        case .hardfailed:
            logger.error("Trust kit validation failed with hardfail")
        }
    }
}
