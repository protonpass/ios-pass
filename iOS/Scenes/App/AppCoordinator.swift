//
// AppCoordinator.swift
// Proton Pass - Created on 02/07/2022.
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
import Entities
import Factory
import Macro
import ProtonCoreAccountRecovery
import ProtonCoreFeatureFlags
import ProtonCoreLogin
import ProtonCorePushNotifications
import SwiftUI

private enum HomeSceneMode {
    case manualLogin
    case manualLoginWithExtraPassword
    case alreadyLoggedIn

    var isManualLogin: Bool {
        switch self {
        case .manualLogin, .manualLoginWithExtraPassword:
            true
        default:
            false
        }
    }

    var extraPassword: Bool {
        if case .manualLoginWithExtraPassword = self {
            return true
        }
        return false
    }
}

@MainActor
final class AppCoordinator {
    private let window: UIWindow
    private let appStateObserver: AppStateObserver
    private var isUITest: Bool

    private var homepageCoordinator: HomepageCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?
    private var rootViewController: UIViewController? { window.rootViewController }

    private var cancellables = Set<AnyCancellable>()

    private var preferences = resolve(\SharedToolingContainer.preferences)
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let appData = resolve(\SharedDataContainer.appData)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let corruptedSessionEventStream = resolve(\SharedDataStreamContainer.corruptedSessionEventStream)
    private var corruptedSessionStream: AnyCancellable?
    private var featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)
    private var pushNotificationService = resolve(\ServiceContainer.pushNotificationService)

    @LazyInjected(\SharedToolingContainer.apiManager) private var apiManager
    @LazyInjected(\SharedUseCasesContainer.wipeAllData) private var wipeAllData

    private let sendErrorToSentry = resolve(\SharedUseCasesContainer.sendErrorToSentry)

    private var theme: Theme {
        preferencesManager.sharedPreferences.unwrapped().theme
    }

    init(window: UIWindow) {
        self.window = window
        appStateObserver = .init()

        isUITest = false
        clearUserDataInKeychainIfFirstRun()
        bindAppState()

        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            resetAllData()
        }

        apiManager.sessionWasInvalidated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionUID in
                guard let self else { return }
                captureErrorAndLogOut(PassError.unexpectedLogout, sessionId: sessionUID)
            }
            .store(in: &cancellables)
    }

    deinit {
        corruptedSessionStream?.cancel()
        corruptedSessionStream = nil
    }

    // swiftlint:disable:next todo
    // TODO: Remove preferences and this function once session migration is done
    private func clearUserDataInKeychainIfFirstRun() {
        guard preferences.isFirstRun else { return }
        preferences.isFirstRun = false
        appData.setUserData(nil)
        appData.setCredential(nil)
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self else { return }
                switch appState {
                case let .loggedOut(reason):
                    logger.info("Logged out \(reason)")
                    if reason != .noAuthSessionButUnauthSessionAvailable {
                        resetAllData()
                    }
                    showWelcomeScene(reason: reason)
                case .alreadyLoggedIn:
                    logger.info("Already logged in")
                    connectToCorruptedSessionStream()
                    showHomeScene(mode: .alreadyLoggedIn)
                    if let sessionID = appData.getCredential()?.sessionID {
                        registerForPushNotificationsIfNeededAndAddHandlers(uid: sessionID)
                    }
                case let .manuallyLoggedIn(userData, extraPassword):
                    logger.info("Logged in manual")
                    appData.setUserData(userData)
                    connectToCorruptedSessionStream()
                    if extraPassword {
                        showHomeScene(mode: .manualLoginWithExtraPassword)
                    } else {
                        showHomeScene(mode: .manualLogin)
                    }
                    registerForPushNotificationsIfNeededAndAddHandlers(uid: userData.credential.sessionID)
                case .undefined:
                    logger.warning("Undefined app state. Don't know what to do...")
                }
            }
            .store(in: &cancellables)

        preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.theme)
            .sink { [weak self] theme in
                guard let self else { return }
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
            }
            .store(in: &cancellables)
    }

    /// Necessary set up like initializing preferences before starting user flow
    func setUpAndStart() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.setUp()
                window.overrideUserInterfaceStyle = theme.userInterfaceStyle
                start()
            } catch {
                appStateObserver.updateAppState(.loggedOut(.failedToInitializePreferences(error)))
            }
        }
    }
}

private extension AppCoordinator {
    func start() {
        if appData.isAuthenticated {
            appStateObserver.updateAppState(.alreadyLoggedIn)
        } else if appData.getCredential() != nil {
            appStateObserver.updateAppState(.loggedOut(.noAuthSessionButUnauthSessionAvailable))
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
        }
    }

    func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiService: apiManager.apiService,
                                                    theme: theme)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        homepageCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [weak self] in
            guard let self else { return }
            handle(logOutReason: reason)
            stopStream()
        }
    }

    func showHomeScene(mode: HomeSceneMode) {
        Task { [weak self] in
            guard let self else {
                return
            }
            if mode.extraPassword {
                do {
                    try await preferencesManager.updateUserPreferences(\.extraPasswordEnabled,
                                                                       value: true)
                } catch {
                    logger.error(error)
                }
            }
            await loginMethod.setLogInFlow(newState: mode.isManualLogin)
            let homepageCoordinator = HomepageCoordinator()
            homepageCoordinator.delegate = self
            self.homepageCoordinator = homepageCoordinator
            welcomeCoordinator = nil
            animateUpdateRootViewController(homepageCoordinator.rootViewController) {
                homepageCoordinator.onboardIfNecessary()
            }
        }
    }

    func showExtraPasswordLockScreen(_ userData: UserData) {
        let onSuccess: () -> Void = { [weak self] in
            guard let self else { return }
            appStateObserver.updateAppState(.manuallyLoggedIn(userData, extraPassword: true))
        }

        let onFailure: () -> Void = { [weak self] in
            guard let self else { return }
            appStateObserver.updateAppState(.loggedOut(.tooManyWrongExtraPasswordAttempts))
        }

        let username = userData.credential.userName
        let view = ExtraPasswordLockView(email: userData.user.email ?? username,
                                         username: username,
                                         onSuccess: onSuccess,
                                         onFailure: onFailure)
        let viewController = UIHostingController(rootView: view)
        animateUpdateRootViewController(viewController)
    }

    func animateUpdateRootViewController(_ newRootViewController: UIViewController,
                                         completion: (() -> Void)? = nil) {
        window.rootViewController = newRootViewController
        UIView.transition(with: window,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: nil) { _ in completion?() }
    }

    func resetAllData() {
        Task { [weak self] in
            guard let self else { return }
            await wipeAllData()
            SharedViewContainer.shared.reset()
        }
    }
}

// MARK: - Utils

private extension AppCoordinator {
    func connectToCorruptedSessionStream() {
        guard corruptedSessionStream == nil else {
            return
        }

        corruptedSessionStream = corruptedSessionEventStream
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0 }
            .sink { [weak self] reason in
                guard let self else { return }
                captureErrorAndLogOut(PassError.corruptedSession(reason), sessionId: reason.sessionId)
            }
    }

    func stopStream() {
        corruptedSessionEventStream.send(nil)
        corruptedSessionStream?.cancel()
        corruptedSessionStream = nil
    }
}

private extension AppCoordinator {
    func registerForPushNotificationsIfNeededAndAddHandlers(uid: String) {
        guard featureFlagsRepository.isEnabled(CoreFeatureFlagType.pushNotifications, reloadValue: true)
        else { return }

        pushNotificationService.setup()
        pushNotificationService.registerForRemoteNotifications(uid: uid)

        guard featureFlagsRepository.isEnabled(CoreFeatureFlagType.accountRecovery, reloadValue: true)
        else { return }

        let passHandler = AccountRecoveryHandler()
        passHandler.handler = { [weak self] _ in
            guard let self else { return .failure(.couldNotOpenAccountRecoveryURL) }
            homepageCoordinator?.accountViewModelWantsToShowAccountRecovery { _ in }
            return .success
        }

        for accountRecoveryType in NotificationType.allAccountRecoveryTypes {
            pushNotificationService.registerHandler(passHandler, forType: accountRecoveryType)
        }
    }
}

private extension AppCoordinator {
    /// Show an alert with a single "OK" button that does nothing
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: #localized("OK"), style: .default))
        rootViewController?.present(alert, animated: true)
    }

    func handle(logOutReason: LogOutReason) {
        switch logOutReason {
        case .expiredRefreshToken, .sessionInvalidated:
            alert(title: #localized("Your session is expired"),
                  message: #localized("Please log in again"))
        case .failedBiometricAuthentication:
            alert(title: #localized("Failed to authenticate"),
                  message: #localized("Please log in again"))
        case let .failedToInitializePreferences(error):
            alert(title: #localized("Error occurred"), message: error.localizedDescription)
        case .tooManyWrongExtraPasswordAttempts:
            alert(title: #localized("Failed to authenticate"),
                  message: #localized("Too many wrong attempts"))
        default:
            break
        }
    }

    func captureErrorAndLogOut(_ error: any Error, sessionId: String) {
        sendErrorToSentry(error, sessionId: sessionId)
        appStateObserver.updateAppState(.loggedOut(.sessionInvalidated))
    }
}

// MARK: - WelcomeCoordinatorDelegate

extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith userData: LoginData) {
        if userData.scopes.contains(where: { $0 == "pass" }) {
            appStateObserver.updateAppState(.manuallyLoggedIn(userData, extraPassword: false))
        } else {
            showExtraPasswordLockScreen(userData)
        }
    }
}

// MARK: - HomepageCoordinatorDelegate

extension AppCoordinator: HomepageCoordinatorDelegate {
    func homepageCoordinatorWantsToLogOut() {
        appStateObserver.updateAppState(.loggedOut(.userInitiated))
    }

    func homepageCoordinatorDidFailLocallyAuthenticating() {
        appStateObserver.updateAppState(.loggedOut(.failedBiometricAuthentication))
    }
}
