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

import Core
import CryptoKit
import GoLibs
import ProtonCore_Authentication
import ProtonCore_FeatureSwitch
import ProtonCore_HumanVerification
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Observability
import ProtonCore_Services

protocol APIManagerDelegate: AnyObject {
    func appLoggedOut()
}

final class APIManager {
    private let logManager: LogManager
    private let logger: Logger
    private let appVer: String

    @KeychainStorage(key: .authSessionData)
    private var authSessionData: SessionData?

    @KeychainStorage(key: .unauthSessionCredentials)
    private var unauthSessionCredentials: AuthCredential?

    private(set) var apiService: APIService
    private(set) var authHelper: AuthHelper
    private(set) var humanHelper: HumanCheckHelper?

    weak var delegate: APIManagerDelegate?

    init(keychain: KeychainProtocol, mainKeyProvider: MainKeyProvider, logManager: LogManager, appVer: String) {
        self.logManager = logManager
        self.appVer = appVer
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self._authSessionData.setKeychain(keychain)
        self._authSessionData.setMainKeyProvider(mainKeyProvider)
        self._authSessionData.setLogManager(logManager)
        self._unauthSessionCredentials.setKeychain(keychain)
        self._unauthSessionCredentials.setMainKeyProvider(mainKeyProvider)
        self._unauthSessionCredentials.setLogManager(logManager)

        if let credential = self._authSessionData.wrappedValue?.userData.credential
            ?? self._unauthSessionCredentials.wrappedValue {
            self.apiService = PMAPIService.createAPIService(
                doh: PPDoH(bundle: .main),
                sessionUID: credential.sessionID,
                challengeParametersProvider: .forAPIService(clientApp: .other(named: "pass"), challenge: .init())
            )
            self.authHelper = AuthHelper(authCredential: credential)
        } else {
            self.apiService = PMAPIService.createAPIServiceWithoutSession(
                doh: PPDoH(bundle: .main),
                challengeParametersProvider: .forAPIService(clientApp: .other(named: "pass"), challenge: .init())
            )
            self.authHelper = AuthHelper()
        }

        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        self.apiService.authDelegate = authHelper
        self.apiService.serviceDelegate = self

        self.setUpCore()
        self.fetchUnauthSessionIfNeeded()

        humanHelper = HumanCheckHelper(apiService: apiService, clientApp: .other(named: "pass"))
        self.apiService.humanDelegate = humanHelper
    }

    func sessionIsAvailable(authCredential: AuthCredential, scopes: Scopes) {
        apiService.setSessionUID(uid: authCredential.sessionID)
        authHelper.onSessionObtaining(credential: Credential(authCredential, scopes: scopes))
    }

    func clearCredentials() {
        unauthSessionCredentials = nil
        apiService.setSessionUID(uid: "")
        // destroying and recreating AuthHelper to clear its cache
        authHelper = AuthHelper()
        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        apiService.authDelegate = authHelper
    }

    private func setUpCore() {
        FeatureFactory.shared.enable(&.observability)
        // Core unauth session feature flag
        FeatureFactory.shared.enable(&.unauthSession)
        #if DEBUG
        FeatureFactory.shared.enable(&.enforceUnauthSessionStrictVerificationOnBackend)
        #endif
        ObservabilityEnv.current.setupWorld(requestPerformer: apiService)
    }

    private func fetchUnauthSessionIfNeeded() {
        guard FeatureFactory.shared.isEnabled(.unauthSession) else { return }

        apiService.acquireSessionIfNeeded { result in
            switch result {
            case .success:
                // session was already available, or servers were
                // reached but returned 4xx/5xx.
                // In both cases we're done here
                break
            case .failure(let error):
                // servers not reachable
                self.logger.error(error)
            }
        }
    }

    // Create a new instance of SessionData with everything copied except credential
    private func updateSessionData(_ sessionData: SessionData,
                                   authCredential: AuthCredential) {
        let currentUserData = sessionData.userData
        let updatedUserData = UserData(credential: authCredential,
                                       user: currentUserData.user,
                                       salts: currentUserData.salts,
                                       passphrases: currentUserData.passphrases,
                                       addresses: currentUserData.addresses,
                                       scopes: currentUserData.scopes)
        self.authSessionData = .init(userData: updatedUserData)
        self.unauthSessionCredentials = nil
    }
}

// MARK: - AuthHelperDelegate
extension APIManager: AuthHelperDelegate {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        clearCredentials()
        if isAuthenticatedSession {
            logger.info("Authenticated session is invalidated. Logging out...")
            authSessionData = nil
            delegate?.appLoggedOut()
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
            fetchUnauthSessionIfNeeded()
        }
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String) {
        logger.info("Session credentials are updated")
        if let sessionData = authSessionData {
            updateSessionData(sessionData, authCredential: authCredential)
        } else {
            unauthSessionCredentials = authCredential
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
        CryptoUpdateTime(serverTime)
    }

    func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        return true
    }
}
