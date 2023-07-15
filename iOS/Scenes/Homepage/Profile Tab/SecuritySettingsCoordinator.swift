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
import Factory
import LocalAuthentication

final class SecuritySettingsCoordinator {
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let logger = Logger(manager: resolve(\SharedToolingContainer.logManager))

    weak var delegate: ChildCoordinatorDelegate?

    init() {}
}

// MARK: - Public APIs

extension SecuritySettingsCoordinator {
    func editMethod() {
        showListOfAvailableMethods()
    }

    func editAppLockTime() {
        showListOfAppLockTimes()
    }

    func editPINCode() {
        definePINCodeAndChangeToPINMethod()
    }
}

// MARK: - Private APIs

private extension SecuritySettingsCoordinator {
    func showListOfAvailableMethods() {
        do {
            let getMethods = resolve(\SharedUseCasesContainer.getLocalAuthenticationMethods)
            let methods = try getMethods()

            let view = LocalAuthenticationMethodsView(supportedMethods: methods,
                                                      onSelect: { [weak self] newMethod in
                                                          self?.updateMethod(newMethod.method)
                                                      })
            let height = OptionRowHeight.compact.value * CGFloat(methods.count) + 60

            delegate?.childCoordinatorWantsToPresent(view: view,
                                                     viewOption: .customSheetWithGrabber(CGFloat(height)),
                                                     presentationOption: .none)
        } catch {
            logger.error(error)
            delegate?.childCoordinatorDidEncounter(error: error)
        }
    }

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
            // Authenticate using `localAuthenticationEnablingPolicy`
            let policy = resolve(\SharedToolingContainer.localAuthenticationEnablingPolicy)
            biometricallyAuthenticateAndUpdateMethod(newMethod, policy: policy)

        case (.biometric, .none),
             (.biometric, .pin):
            // Disable biometric authentication or change from biometric to PIN
            // Authenticate using `localAuthenticationAuthenticatingPolicy`
            let policy = resolve(\SharedToolingContainer.localAuthenticationAuthenticatingPolicy)
            biometricallyAuthenticateAndUpdateMethod(newMethod, policy: policy)

        case (.none, .pin):
            // Enable PIN authentication
            definePINCodeAndChangeToPINMethod()

        case (.pin, .biometric),
             (.pin, .none):
            // Disable PIN authentication or change from PIN to biometric
            delegate?.childCoordinatorWantsToDismissTopViewController()
        }
    }

    func biometricallyAuthenticateAndUpdateMethod(_ newMethod: LocalAuthenticationMethod,
                                                  policy: LAPolicy) {
        delegate?.childCoordinatorWantsToDismissTopViewController()
        let authenticate = resolve(\SharedUseCasesContainer.authenticateBiometrically)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let authenticate = try await authenticate(reason: "Please authenticate")
                if authenticate {
                    self.preferences.localAuthenticationMethod = newMethod
                }
            } catch {
                self.delegate?.childCoordinatorDidEncounter(error: error)
            }
        }
    }

    func showListOfAppLockTimes() {
        let view = EditAppLockTimeView(selectedAppLockTime: preferences.appLockTime,
                                       onSelect: { [weak self] newTime in
                                           self?.updateAppLockTime(newTime)
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
        let view = SetPINCodeView { [weak self] pinCode in
            guard let self else { return }
            self.preferences.localAuthenticationMethod = .pin
            self.preferences.pinCode = pinCode
            self.delegate?.childCoordinatorWantsToDisplayBanner(bannerOption: .success("PIN code set"),
                                                                presentationOption: .dismissTopViewController)
        }
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .sheet,
                                                 presentationOption: .dismissTopViewController)
    }
}
