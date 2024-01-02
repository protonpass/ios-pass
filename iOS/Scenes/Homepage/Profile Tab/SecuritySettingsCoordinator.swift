//
// SecuritySettingsCoordinator.swift
// Proton Pass - Created on 14/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import Factory
import LocalAuthentication
import Macro

@MainActor
final class SecuritySettingsCoordinator {
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let authenticate = resolve(\SharedUseCasesContainer.authenticateBiometrically)
    private let getMethods = resolve(\SharedUseCasesContainer.getLocalAuthenticationMethods)
    private let enablingPolicy = resolve(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private var authenticatingPolicy: LAPolicy { preferences.localAuthenticationPolicy }
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ChildCoordinatorDelegate?

    init() {}
}

// MARK: - Public APIs

extension SecuritySettingsCoordinator {
    @MainActor
    func editMethod() {
        showListOfAvailableMethods()
    }

    @MainActor
    func editAppLockTime() {
        showListOfAppLockTimes()
    }

    @MainActor
    func editPINCode() {
        verifyAndThenUpdatePIN()
    }
}

// MARK: - Private APIs

private extension SecuritySettingsCoordinator {
    @MainActor
    func showListOfAvailableMethods() {
        do {
            let methods = try getMethods(policy: enablingPolicy)
            let view = LocalAuthenticationMethodsView(supportedMethods: methods,
                                                      onSelect: { [weak self] newMethod in
                                                          guard let self else { return }
                                                          updateMethod(newMethod.method)
                                                      })
            let height = OptionRowHeight.compact.value * CGFloat(methods.count) + 60

            delegate?.childCoordinatorWantsToPresent(view: view,
                                                     viewOption: .customSheetWithGrabber(CGFloat(height)),
                                                     presentationOption: .none)
        } catch {
            logger.error(error)
            router.display(element: .displayErrorBanner(error))
        }
    }

    @MainActor
    func updateMethod(_ newMethod: LocalAuthenticationMethod) {
        let currentMethod = preferences.localAuthenticationMethod
        switch (currentMethod, newMethod) {
        case (.biometric, .biometric),
             (.none, .none),
             (.pin, .pin):
            // No changes, just dismiss the method list & do nothing
            delegate?.childCoordinatorWantsToDismissTopViewController()

        case (.none, .biometric):
            // Enable biometric authentication
            // Failure is allowed because biometric authentication is not yet turned on
            biometricallyAuthenticateAndUpdateMethod(newMethod,
                                                     policy: enablingPolicy,
                                                     allowFailure: true)

        case (.biometric, .none),
             (.biometric, .pin):
            // Disable biometric authentication or change from biometric to PIN
            // Failure is not allowed because biometric authentication is already turned on
            // Log out if too many failures
            biometricallyAuthenticateAndUpdateMethod(newMethod,
                                                     policy: authenticatingPolicy,
                                                     allowFailure: false)

        case (.none, .pin):
            // Enable PIN authentication
            definePINCodeAndChangeToPINMethod()

        case (.pin, .biometric),
             (.pin, .none):
            // Disable PIN authentication or change from PIN to biometric
            verifyPINCodeAndUpdateMethod(newMethod)
        }
    }

    @MainActor
    func biometricallyAuthenticateAndUpdateMethod(_ newMethod: LocalAuthenticationMethod,
                                                  policy: LAPolicy,
                                                  allowFailure: Bool) {
        let succesHandler: () -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorWantsToDismissTopViewController()

            if newMethod != .biometric {
                preferences.fallbackToPasscode = true
            }

            if newMethod == .pin {
                // Delay a bit to wait for cover/uncover app animation to finish before presenting new sheet
                // (see "sceneWillResignActive" & "sceneDidBecomeActive" in SceneDelegate)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let self else { return }
                    definePINCodeAndChangeToPINMethod()
                }
            } else {
                preferences.localAuthenticationMethod = newMethod
            }
        }

        let failureHandler: () -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }

        if allowFailure {
            delegate?.childCoordinatorWantsToDismissTopViewController()

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let authenticate = try await authenticate(policy: policy)
                    if authenticate {
                        succesHandler()
                    }
                } catch {
                    router.display(element: .displayErrorBanner(error))
                }
            }
        } else {
            let view = LocalAuthenticationView(mode: .biometric,
                                               delayed: false,
                                               onAuth: {},
                                               onSuccess: succesHandler,
                                               onFailure: failureHandler)
            delegate?.childCoordinatorWantsToPresent(view: view,
                                                     viewOption: .fullScreen,
                                                     presentationOption: .dismissTopViewController)
        }
    }

    @MainActor
    func showListOfAppLockTimes() {
        let view = EditAppLockTimeView(selectedAppLockTime: preferences.appLockTime,
                                       onSelect: { [weak self] newTime in
                                           guard let self else { return }
                                           updateAppLockTime(newTime)
                                       })
        let height = OptionRowHeight.compact.value * CGFloat(AppLockTime.allCases.count) + 60
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .customSheetWithGrabber(height),
                                                 presentationOption: .none)
    }

    func updateAppLockTime(_ newAppLockTime: AppLockTime) {
        preferences.appLockTime = newAppLockTime
        delegate?.childCoordinatorWantsToDismissTopViewController()
    }

    func definePINCodeAndChangeToPINMethod() {
        router.present(for: .setPINCode)
    }

    @MainActor
    func verifyPINCodeAndUpdateMethod(_ newMethod: LocalAuthenticationMethod) {
        let successHandler: () -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorWantsToDismissTopViewController()

            if newMethod == .biometric {
                biometricallyAuthenticateAndUpdateMethod(.biometric,
                                                         policy: enablingPolicy,
                                                         allowFailure: true)
            } else {
                preferences.localAuthenticationMethod = newMethod
            }
        }

        let failureHandler: () -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }

        let view = LocalAuthenticationView(mode: .pin,
                                           delayed: false,
                                           onAuth: {},
                                           onSuccess: successHandler,
                                           onFailure: failureHandler)
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .fullScreen,
                                                 presentationOption: .dismissTopViewController)
    }

    @MainActor
    func verifyAndThenUpdatePIN() {
        let successHandler: () -> Void = { [weak self] in
            guard let self else { return }
            definePINCodeAndChangeToPINMethod()
        }

        let failureHandler: () -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }

        let view = LocalAuthenticationView(mode: .pin,
                                           delayed: false,
                                           onAuth: {},
                                           onSuccess: successHandler,
                                           onFailure: failureHandler)
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .fullScreen,
                                                 presentationOption: .dismissTopViewController)
    }
}
