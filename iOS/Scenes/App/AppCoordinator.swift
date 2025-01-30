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
import CoreSpotlight
import Entities
import Factory
import Macro
import ProtonCoreAccountRecovery
import ProtonCoreFeatureFlags
@preconcurrency import ProtonCoreLogin
@preconcurrency import ProtonCoreLoginUI
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
    private let appData = resolve(\SharedDataContainer.appData)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)

    @LazyInjected(\SharedToolingContainer.keychain) private var keychain
    @LazyInjected(\SharedToolingContainer.apiManager) private var apiManager
    @LazyInjected(\SharedToolingContainer.preferencesManager) var preferencesManager
    @LazyInjected(\SharedToolingContainer.authManager) private var authManager

    @LazyInjected(\SharedRepositoryContainer.featureFlagsRepository) private var featureFlagsRepository
    @LazyInjected(\SharedRepositoryContainer.localUserDataDatasource) var localUserDataDatasource

    @LazyInjected(\SharedUseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching
    @LazyInjected(\SharedUseCasesContainer.refreshFeatureFlags) private var refreshFeatureFlags
    @LazyInjected(\SharedUseCasesContainer.setUpCoreTelemetry) private var setUpCoreTelemetry
    @LazyInjected(\SharedUseCasesContainer.logOutUser) var logOutUser
    @LazyInjected(\SharedUseCasesContainer.logOutAllAccounts) var logOutAllAccounts
    @LazyInjected(\SharedUseCasesContainer.sendErrorToSentry) var sendErrorToSentry
    @LazyInjected(\SharedUseCasesContainer.sendMessageToSentry) var sendMessageToSentry
    @LazyInjected(\SharedUseCasesContainer.clearCacheForLoggedOutUsers)
    private var clearCacheForLoggedOutUsers

    private var authDeviceManagerUI: AuthDeviceManagerUI?

    //    @LazyInjected(\ServiceContainer.pushNotificationService) private var pushNotificationService

    private var task: Task<Void, Never>?

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
    }

    // swiftlint:disable:next todo
    // TODO: Remove preferences and this function once session migration is done
    private func clearUserDataInKeychainIfFirstRun() {
        guard preferences.isFirstRun else { return }
        preferences.isFirstRun = false
        appData.resetData()
        try? keychain.removeOrError(forKey: AuthManager.storageKey)
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
                    showWelcomeScene(reason: reason)
                case .alreadyLoggedIn:
                    logger.info("Already logged in")
                    showHomeScene(mode: .alreadyLoggedIn)
                    if let userId = userManager.activeUserId,
                       authManager.getCredential(userId: userId)?.sessionID != nil {
                        registerForPushNotificationsIfNeededAndAddHandlers( /* uid: sessionID */ )
                    }
                    authDeviceManagerUI?.setup()
                    fetchAuthPendingDevices()
                case let .manuallyLoggedIn(userData, extraPassword):
                    Task { [weak self] in
                        guard let self else {
                            return
                        }
                        logger.info("Logged in manual")
                        try? await userManager.upsertAndMarkAsActive(userData: userData)

                        if extraPassword {
                            showHomeScene(mode: .manualLoginWithExtraPassword)
                        } else {
                            showHomeScene(mode: .manualLogin)
                        }
                        registerForPushNotificationsIfNeededAndAddHandlers(/* uid: userData.credential.sessionID */ )
                        authDeviceManagerUI?.setup()
                        fetchAuthPendingDevices()
                    }
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

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                logOutIfNoUserDataFound()
                clearCachedFilesForLoggedOutUsers()
            }
            .store(in: &cancellables)
    }

    /// Necessary set up like initializing preferences before starting user flow
    func setUpAndStart() async -> Bool {
        do {
            try await setUpBeforeLaunching(rootContainer: .window(window))
            start()
            refreshFeatureFlags()
            setUpCoreTelemetry()

            authDeviceManagerUI = AuthDeviceManagerUI(authDeviceManager: .init(userManagerProvider: userManager,
                                                                               apiManagerProvider: apiManager))

            authManager.sessionWasInvalidated
                .receive(on: DispatchQueue.main)
                .sink { [weak self] sessionInfos in
                    guard let self, task == nil else { return }
                    task = Task { [weak self] in
                        guard let self, let userId = sessionInfos.userId else { return }
                        defer { task = nil }
                        do {
                            let userData = try await userManager.getUserData(userId)
                            if try await logOutUser(userId: userId) {
                                appStateObserver.updateAppState(.loggedOut(.sessionInvalidated))
                            } else if let email = userData?.user.email {
                                alert(title: #localized("Session expired"),
                                      message: #localized("You're logged out from %@", email))
                            }
                            sendMessageToSentry("Invalidated session",
                                                userId: userId,
                                                sessionId: sessionInfos.sessionId)
                        } catch {
                            sendErrorToSentry(error,
                                              userId: userId,
                                              sessionId: sessionInfos.sessionId)
                        }
                    }
                }
                .store(in: &cancellables)

//            apiManager.apiServiceWereUpdated
//                .receive(on: DispatchQueue.main)
//                .sink { [weak self] in
//                    guard let self else { return }
//                    setUpCoreTelemetry()
//                    refreshFeatureFlags()
//                }
//                .store(in: &cancellables)
            return true
        } catch {
            appStateObserver.updateAppState(.loggedOut(.failedToSetUpAppCoordinator(error)))
            // When running into set up error, we delete all data locally
            // So we try our best effort to set up everything again here in clean state
            try? await setUpBeforeLaunching(rootContainer: .window(window))
            return false
        }
    }
}

private extension AppCoordinator {
    func start() {
        if let userId = userManager.activeUserId,
           authManager.isAuthenticated(userId: userId) {
            appStateObserver.updateAppState(.alreadyLoggedIn)
        } else if let userId = userManager.activeUserId,
                  authManager.getCredential(userId: userId) != nil {
            appStateObserver.updateAppState(.loggedOut(.noAuthSessionButUnauthSessionAvailable))
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
        }
    }

    func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiService: apiManager.getUnauthApiService(),
                                                    theme: theme)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        homepageCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [weak self] in
            guard let self else { return }
            handle(logOutReason: reason)
        }

        // When user is not logged in, remove all indexed data for Spotlight
        Task {
            try? await CSSearchableIndex.default().deleteAllSearchableItems()
        }
    }

    func showHomeScene(mode: HomeSceneMode) {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                // Refresh cached preferences after every login
                try await preferencesManager.setUp()
                if mode.extraPassword {
                    try await preferencesManager.updateUserPreferences(\.extraPasswordEnabled,
                                                                       value: true)
                }
            } catch {
                logger.error(error)
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
        let view = ExtraPasswordLockView(apiServicing: apiManager,
                                         email: userData.user.email ?? username,
                                         username: username,
                                         userId: userData.user.ID,
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
        Task {
            // swiftlint:disable:next todo
            // TODO: why did we reset the root view controller and banner manager ?
            SharedViewContainer.shared.reset()
        }
    }

    // Check if user is logged out from extensions
    func logOutIfNoUserDataFound() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let users = try await localUserDataDatasource.getAll()
                if users.isEmpty, try await !userManager.getAllUsers().isEmpty {
                    // Refresh all on-memory data and stop the event loop
                    try await logOutAllAccounts()
                    appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
                }
            } catch {
                logger.error(error)
            }
        }
    }

    func clearCachedFilesForLoggedOutUsers() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await clearCacheForLoggedOutUsers()
            } catch {
                logger.error(error)
            }
        }
    }

    func fetchAuthPendingDevices() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            authDeviceManagerUI?.forceFetchPendingDevices()
        }
    }
}

private extension AppCoordinator {
    func registerForPushNotificationsIfNeededAndAddHandlers( /* uid: String */ ) {
        guard featureFlagsRepository.isEnabled(CoreFeatureFlagType.pushNotifications, reloadValue: true)
        else { return }

//        pushNotificationService.setup()
//        pushNotificationService.registerForRemoteNotifications(uid: uid)

        guard featureFlagsRepository.isEnabled(CoreFeatureFlagType.accountRecovery, reloadValue: true)
        else { return }

        let passHandler = AccountRecoveryHandler()
        passHandler.handler = { [weak self] _ in
            guard let self else { return .failure(.couldNotOpenAccountRecoveryURL) }
            homepageCoordinator?.accountViewModelWantsToShowAccountRecovery { _ in }
            return .success
        }

//        for accountRecoveryType in NotificationType.allAccountRecoveryTypes {
//            pushNotificationService.registerHandler(passHandler, forType: accountRecoveryType)
//        }
    }
}

private extension AppCoordinator {
    /// Show an alert with a single "OK" button that dismisses all current sheets
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: #localized("OK"), style: .default) { [weak self] _ in
            guard let self else { return }
            rootViewController?.dismiss(animated: true)
        }
        alert.addAction(okAction)
        rootViewController?.topMostViewController.present(alert, animated: true)
    }

    func handle(logOutReason: LogOutReason) {
        switch logOutReason {
        case .expiredRefreshToken, .sessionInvalidated:
            alert(title: #localized("Your session is expired"),
                  message: #localized("Please log in again"))
        case let .failedBiometricAuthentication(reason):
            alert(title: reason ?? #localized("Failed to authenticate"),
                  message: #localized("Please log in again"))
        case let .failedToSetUpAppCoordinator(error):
            alert(title: #localized("Error occurred"), message: error.localizedDescription)
        case .tooManyWrongExtraPasswordAttempts:
            alert(title: #localized("Failed to authenticate"),
                  message: #localized("Too many wrong attempts"))
        default:
            break
        }
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

    func homepageCoordinatorDidFailLocallyAuthenticating(_ errorMessage: String?) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                try await logOutAllAccounts()
                appStateObserver.updateAppState(.loggedOut(.failedBiometricAuthentication(errorMessage)))
            } catch {
                logger.error(error)
            }
        }
    }
}
