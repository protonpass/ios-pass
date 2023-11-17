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
import SwiftUI
import UIKit

protocol APIManagerDelegate: AnyObject {
    func appLoggedOutBecauseSessionWasInvalidated()
}

final class APIManager {
    private let logger = resolve(\SharedToolingContainer.logger)
    private let appVer = resolve(\SharedToolingContainer.appVersion)
    private let appData = resolve(\SharedDataContainer.appData)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let trustKitDelegate: TrustKitDelegate

    private(set) var apiService: APIService
    private(set) var authHelper: PassAuthHelper
    private(set) var forceUpgradeHelper: ForceUpgradeHelper?
    private(set) var humanHelper: HumanCheckHelper?

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: APIManagerDelegate?

    init() {
        let trustKitDelegate = PassTrustKitDelegate()
        APIManager.setUpCertificatePinning(trustKitDelegate: trustKitDelegate)
        self.trustKitDelegate = trustKitDelegate

        let doh = ProtonPassDoH()
        let apiService: PMAPIService
        let challengeProvider = ChallengeParametersProvider.forAPIService(clientApp: .pass,
                                                                          challenge: .init())
        if let credential = appData
            .getCredentials() /* appData.getUserData()?.credential ?? appData.getUnauthCredential()*/ {
            apiService = PMAPIService.createAPIService(doh: doh,
                                                       sessionUID: credential.sessionID,
                                                       challengeParametersProvider: challengeProvider)
//            authHelper = AuthHelper(authCredential: credential)
        } else {
            apiService = PMAPIService.createAPIServiceWithoutSession(doh: doh,
                                                                     challengeParametersProvider: challengeProvider)
//            authHelper = AuthHelper()
        }
        authHelper = PassAuthHelper(userDataProvider: appData)
        self.apiService = apiService
        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        self.apiService.authDelegate = authHelper
        self.apiService.serviceDelegate = self
        apiService.loggingDelegate = self

        humanHelper = HumanCheckHelper(apiService: apiService,
                                       inAppTheme: { [weak self] in
                                           guard let self else { return .matchSystem }
                                           return preferences.theme.inAppTheme
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
//        useNewTokensWhenAppBackToForegound()
    }

    func sessionIsAvailable(authCredential: AuthCredential, scopes: Scopes) {
        apiService.setSessionUID(uid: authCredential.sessionID)
        authHelper.onSessionObtaining(credential: Credential(authCredential, scopes: scopes))
    }

    func clearCredentials() {
        print("Woot cleared credential")

        appData.setCredentials(nil)
//        appData.setUnauthCredential(nil)
//        apiService.setSessionUID(uid: "")
        // destroying and recreating AuthHelper to clear its cache
//        authHelper = PassAuthHelper(userDataProvider: appData)
//        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
//        apiService.authDelegate = authHelper
    }

    private static func setUpCertificatePinning(trustKitDelegate: TrustKitDelegate) {
        TrustKitWrapper.setUp(delegate: trustKitDelegate)
        let trustKit = TrustKitWrapper.current
        PMAPIService.trustKit = trustKit
        PMAPIService.noTrustKit = trustKit == nil
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
                guard let self else { return }
                appData.invalidateCachedUserData()
                if let userData = appData.getUserData() {
                    authHelper.onSessionObtaining(credential: userData.getCredential)
                }
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
        appData.setUserData(updatedUserData)
        appData.setCredentials(authCredential)
//        appData.setUnauthCredential(nil)
    }
}

// MARK: - AuthHelperDelegate

extension APIManager: AuthHelperDelegate {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        print("Woot invalidated session UID \(sessionUID)")

        if isAuthenticatedSession {
            logger.info("Authenticated session is invalidated. Logging out.")
            appData.setUserData(nil)
            appData.setCredentials(nil)
            delegate?.appLoggedOutBecauseSessionWasInvalidated()
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
            fetchUnauthSessionIfNeeded()
        }
        clearCredentials()
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String) {
        logger.info("Session credentials are updated")
        if let userData = appData.getUserData() {
            update(userData: userData, authCredential: authCredential)
        } else {
            appData.setCredentials(authCredential)
//            appData.setUnauthCredential(authCredential)
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

import Foundation
import ProtonCoreLog
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities

public final class PassAuthHelper: AuthDelegate {
    private let userDataProvider: AppData

    public private(set) weak var delegate: AuthHelperDelegate?
    public weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?

    init(userDataProvider: AppData) {
        self.userDataProvider = userDataProvider
    }

    public func setUpDelegate(_ delegate: AuthHelperDelegate,
                              callingItOn executor: CompletionBlockExecutor? = nil) {
//        if let executor {
//            delegateExecutor = executor
//        } else {
//            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
//            delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
//        }
        self.delegate = delegate
    }

    public func credential(sessionUID: String) -> Credential? {
        guard let authCredential = userDataProvider
            .getCredentials() /* userDataProvider.getUserData()?.credential ?? userDataProvider.getUnauthCredential() */
        else {
            return nil
        }

        return Credential(authCredential)
    }

    public func authCredential(sessionUID: String) -> AuthCredential? {
        print("Woot session UID \(sessionUID)")
        if userDataProvider.getCredentials()?.sessionID == sessionUID {
            print("Woot session credential \(userDataProvider.getCredentials()?.debug)")

            return userDataProvider.getCredentials()
        }
        return nil
    }

    public func onUpdate(credential: Credential, sessionUID: String) {
        guard let authCredential = userDataProvider.getUserData()?.credential else {
//            userDataProvider.setUserData(userDataProvider.getUserData()?.copy(with: AuthCredential(credential)))
            userDataProvider.setCredentials(AuthCredential(credential))
            return
        }
        guard authCredential.sessionID == sessionUID else {
            PMLog
                .error("Asked for updating credentials of a wrong session. It's a programmers error and should be investigated")
            return
        }

        let updatedAuth = authCredential.updatedKeepingKeyAndPasswordDataIntact(credential: credential)
        var updatedCredentials = credential
//        if updatedCredentials.scopes.isEmpty {
//            updatedCredentials.scopes = existingCredentials.1.scopes
//        }
//        userDataProvider.setUserData(userDataProvider.getUserData()?.copy(with: updatedAuth))
        userDataProvider.setCredentials(updatedAuth)
        delegate?.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials,
                                         for: sessionUID)
    }

    public func onSessionObtaining(credential: Credential) {
        let authCredentials = AuthCredential(credential)
//        let newUserData = userDataProvider.getUserData()?.copy(with: authCredentials)
//        userDataProvider.setUserData(newUserData)
        userDataProvider.setCredentials(authCredentials)
        delegate?.credentialsWereUpdated(authCredential: authCredentials,
                                         credential: credential,
                                         for: credential.UID)
    }

    public func onAdditionalCredentialsInfoObtained(sessionUID: String,
                                                    password: String?,
                                                    salt: String?,
                                                    privateKey: String?) {
        guard let authCredential = userDataProvider.getUserData()?.credential else {
            return
        }
        guard authCredential.sessionID == sessionUID else {
            PMLog
                .error("Asked for updating credentials of a wrong session. It's a programmers error and should be investigated")
            return
        }

        if let password {
            authCredential.update(password: password)
        }
        let saltToUpdate = salt ?? authCredential.passwordKeySalt
        let privateKeyToUpdate = privateKey ?? authCredential.privateKey
        authCredential.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)

//        let newUserData = userDataProvider.getUserData()?.copy(with: authCredential)
//        userDataProvider.setUserData(newUserData)
        userDataProvider.setCredentials(authCredential)
        guard let delegate else { return }
        delegate.credentialsWereUpdated(authCredential: authCredential,
                                        credential: Credential(authCredential),
                                        for: sessionUID)
    }

    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
        guard let authCredential = userDataProvider.getCredentials() else {
            return
        }
        guard authCredential.sessionID == sessionUID else {
            PMLog.error("Asked for logout of wrong session. It's a programmers error and should be investigated")
            return
        }
//        userDataProvider.setUserData(nil)
        userDataProvider.setCredentials(nil)
        delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
        authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID,
                                                                               isAuthenticatedSession: true)
    }

    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
        guard let authCredential = userDataProvider.getCredentials() else {
            return
        }
        guard authCredential.sessionID == sessionUID else {
            PMLog
                .error("Asked for erasing the credentials of a wrong session. It's a programmers error and should be investigated")
            return
        }
//        userDataProvider.setUserData(nil)
        userDataProvider.setCredentials(nil)
        delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
        authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID,
                                                                               isAuthenticatedSession: false)
    }
}

extension AuthCredential {
    var debug: String {
        "session \(sessionID), token \(accessToken), refresh \(refreshToken), user \(userName)"
    }
}

// public final class AuthHelper: AuthDelegate {
//
//    private let currentCredentials: Atomic<(AuthCredential, Credential)?>
//
//    public private(set) weak var delegate: AuthHelperDelegate?
//    public weak var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate?
//    private var delegateExecutor: CompletionBlockExecutor?
//
//    public init(authCredential: AuthCredential) {
//        let credential = Credential(authCredential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init(credential: Credential) {
//        let authCredential = AuthCredential(credential)
//        self.currentCredentials = .init((authCredential, credential))
//    }
//
//    public init() {
//        self.currentCredentials = .init(nil)
//    }
//
//    public init?(initialBothCredentials: (AuthCredential, Credential)) {
//        let authCredential = initialBothCredentials.0
//        let credential = initialBothCredentials.1
//        guard authCredential.sessionID == credential.UID,
//              authCredential.accessToken == credential.accessToken,
//              authCredential.refreshToken == credential.refreshToken,
//              authCredential.userID == credential.userID,
//              authCredential.userName == credential.userName else {
//            return nil
//        }
//        self.currentCredentials = .init(initialBothCredentials)
//    }
//
//    public func setUpDelegate(_ delegate: AuthHelperDelegate, callingItOn executor: CompletionBlockExecutor? =
//    nil) {
//        if let executor = executor {
//            self.delegateExecutor = executor
//        } else {
//            let dispatchQueue = DispatchQueue(label: "me.proton.core.auth-helper.default", qos: .userInitiated)
//            self.delegateExecutor = .asyncExecutor(dispatchQueue: dispatchQueue)
//        }
//        self.delegate = delegate
//    }
//
//    public func credential(sessionUID: String) -> Credential? {
//        fetchCredentials(for: sessionUID, path: \.1)
//    }
//
//    public func authCredential(sessionUID: String) -> AuthCredential? {
//        fetchCredentials(for: sessionUID, path: \.0)
//    }
//
//    private func fetchCredentials<T>(for sessionUID: String, path: KeyPath<(AuthCredential, Credential), T>) ->
//    T? {
//        currentCredentials.transform { authCredentials in
//            guard let existingCredentials = authCredentials else { return nil }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for wrong credentials. It's a programmers error and should be investigated")
//                return nil
//            }
//            return existingCredentials[keyPath: path]
//        }
//    }
//
//    public func onUpdate(credential: Credential, sessionUID: String) {
//        currentCredentials.mutate { credentialsToBeUpdated in
//
//            guard let existingCredentials = credentialsToBeUpdated else {
//                credentialsToBeUpdated = (AuthCredential(credential), credential)
//                return
//            }
//
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated")
//                return
//            }
//
//            // we don't nil out the key and password to avoid loosing this information unintentionaly
//            let updatedAuth = existingCredentials.0.updatedKeepingKeyAndPasswordDataIntact(credential:
//            credential)
//            var updatedCredentials = credential
//
//            // if there's no update in scopes, assume the same scope as previously
//            if updatedCredentials.scopes.isEmpty {
//                updatedCredentials.scopes = existingCredentials.1.scopes
//            }
//
//            credentialsToBeUpdated = (updatedAuth, updatedCredentials)
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: updatedAuth, credential: updatedCredentials, for: sessionUID)
//            }
//        }
//    }
//
//    public func onSessionObtaining(credential: Credential) {
//        currentCredentials.mutate { authCredentials in
//
//            let sessionUID = credential.UID
//            let newCredentials = (AuthCredential(credential), credential)
//
//            authCredentials = newCredentials
//
//            guard let delegate, let delegateExecutor else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: newCredentials.0, credential: newCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?,
//    privateKey: String?) {
//        currentCredentials.mutate { authCredentials in
//            guard authCredentials != nil else { return }
//            guard authCredentials?.0.sessionID == sessionUID else {
//                PMLog.error("Asked for updating credentials of a wrong session. It's a programmers error and
//                should be investigated")
//                return
//            }
//
//            if let password = password {
//                authCredentials?.0.update(password: password)
//            }
//            let saltToUpdate = salt ?? authCredentials?.0.passwordKeySalt
//            let privateKeyToUpdate = privateKey ?? authCredentials?.0.privateKey
//            authCredentials?.0.update(salt: saltToUpdate, privateKey: privateKeyToUpdate)
//
//            guard let delegate, let delegateExecutor, let existingCredentials = authCredentials else { return }
//            delegateExecutor.execute {
//                delegate.credentialsWereUpdated(authCredential: existingCredentials.0, credential: existingCredentials.1, for: sessionUID)
//            }
//        }
//    }
//
//    public func onAuthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for logout of wrong session. It's a programmers error and should be
//                investigated")
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: true)
//        }
//    }
//
//    public func onUnauthenticatedSessionInvalidated(sessionUID: String) {
//        currentCredentials.mutate { authCredentials in
//            guard let existingCredentials = authCredentials else { return }
//            guard existingCredentials.0.sessionID == sessionUID else {
//                PMLog.error("Asked for erasing the credentials of a wrong session. It's a programmers error and
//                should be investigated")
//                return
//            }
//            authCredentials = nil
//
//            delegateExecutor?.execute { [weak self] in
//                self?.delegate?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//            }
//            authSessionInvalidatedDelegateForLoginAndSignup?.sessionWasInvalidated(for: sessionUID, isAuthenticatedSession: false)
//        }
//    }
// }
//
//

extension UserData {
    func copy(with newAuthCredential: AuthCredential) -> UserData {
        UserData(credential: newAuthCredential,
                 user: user,
                 salts: salts,
                 passphrases: passphrases,
                 addresses: addresses,
                 scopes: scopes)
    }
}
