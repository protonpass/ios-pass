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
import ProtonCore_Challenge
import ProtonCore_Environment
import ProtonCore_FeatureSwitch
import ProtonCore_ForceUpgrade
import ProtonCore_HumanVerification
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Observability
import ProtonCore_Services

let kAppStoreUrlString = "itms-apps://itunes.apple.com/app/id6443490629"

protocol APIManagerDelegate: AnyObject {
    func appLoggedOutBecauseSessionWasInvalidated()
}

final class APIManager {
    private let logManager: LogManager
    private let logger: Logger
    private let appVer: String
    private let appData: AppData
    private let trustKitDelegate: LoggingTrustKitDelegate

    private(set) var apiService: APIService
    private(set) var authHelper: AuthHelper
    private(set) var forceUpgradeHelper: ForceUpgradeHelper?
    private(set) var humanHelper: HumanCheckHelper?

    weak var delegate: APIManagerDelegate?

    init(logManager: LogManager, appVer: String, appData: AppData) {
        let logger = Logger(manager: logManager)
        let trustKitDelegate = LoggingTrustKitDelegate(logger: logger)
        APIManager.setUpCertificatePinning(trustKitDelegate: trustKitDelegate)

        self.trustKitDelegate = trustKitDelegate
        self.logManager = logManager
        self.appVer = appVer
        self.logger = logger
        self.appData = appData

        if let credential = appData.userData?.credential ?? appData.unauthSessionCredentials {
            self.apiService = PMAPIService.createAPIService(
                doh: ProtonPassDoH(),
                sessionUID: credential.sessionID,
                challengeParametersProvider: .forAPIService(clientApp: .other(named: "pass"), challenge: .init())
            )
            self.authHelper = AuthHelper(authCredential: credential)
        } else {
            self.apiService = PMAPIService.createAPIServiceWithoutSession(
                doh: ProtonPassDoH(),
                challengeParametersProvider: .forAPIService(clientApp: .other(named: "pass"), challenge: .init())
            )
            self.authHelper = AuthHelper()
        }

        authHelper.setUpDelegate(self, callingItOn: .immediateExecutor)
        self.apiService.authDelegate = authHelper
        self.apiService.serviceDelegate = self

        self.humanHelper = HumanCheckHelper(apiService: apiService, clientApp: .other(named: "pass"))
        self.apiService.humanDelegate = humanHelper

        // swiftlint:disable:next force_unwrapping
        self.forceUpgradeHelper = ForceUpgradeHelper(config: .mobile(URL(string: kAppStoreUrlString)!),
                                                     responseDelegate: self)
        self.apiService.forceUpgradeDelegate = forceUpgradeHelper

        self.setUpCore()
        self.fetchUnauthSessionIfNeeded()
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
        FeatureFactory.shared.enable(&.observability)
        // Core unauth session feature flag
        FeatureFactory.shared.enable(&.unauthSession)

        FeatureFactory.shared.enable(&.externalSignup)
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

    // Create a new instance of UserData with everything copied except credential
    private func update(userData: UserData, authCredential: AuthCredential) {
        let updatedUserData = UserData(credential: authCredential,
                                       user: userData.user,
                                       salts: userData.salts,
                                       passphrases: userData.passphrases,
                                       addresses: userData.addresses,
                                       scopes: userData.scopes)
        self.appData.userData = updatedUserData
        self.appData.unauthSessionCredentials = nil
    }
}

// MARK: - AuthHelperDelegate
extension APIManager: AuthHelperDelegate {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool) {
        clearCredentials()
        if isAuthenticatedSession {
            logger.info("Authenticated session is invalidated. Logging out...")
            appData.userData = nil
            delegate?.appLoggedOutBecauseSessionWasInvalidated()
        } else {
            logger.info("Unauthenticated session is invalidated. Credentials are erased, fetching new ones")
            fetchUnauthSessionIfNeeded()
        }
    }

    func credentialsWereUpdated(authCredential: AuthCredential, credential: Credential, for sessionUID: String) {
        logger.info("Session credentials are updated")
        if let userData = appData.userData {
            update(userData: userData, authCredential: authCredential)
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
        CryptoUpdateTime(serverTime)
    }

    func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        return true
    }
}

// MARK: - ForceUpgradeResponseDelegate
extension APIManager: ForceUpgradeResponseDelegate {
    func onQuitButtonPressed() {}
    func onUpdateButtonPressed() {}
}

// MARK: - TrustKitDelegate
private class LoggingTrustKitDelegate: TrustKitDelegate {
    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

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
