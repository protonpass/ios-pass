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
import DesignSystem
import Entities
import Factory
import LocalAuthentication
import Macro

@MainActor
final class SecuritySettingsCoordinator {
    private let logger = resolve(\SharedToolingContainer.logger)
    private let authenticate = resolve(\SharedUseCasesContainer.authenticateBiometrically)
    private let enablingPolicy = resolve(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)
    private let updateSharedPreferences = resolve(\SharedUseCasesContainer.updateSharedPreferences)

    weak var delegate: (any ChildCoordinatorDelegate)?

    private var preferences: SharedPreferences { getSharedPreferences() }

    init() {}
}

// MARK: - Public APIs

extension SecuritySettingsCoordinator {
    func editMethod(_ supportedMethods: [LocalAuthenticationMethodUiModel]) {
        let update: (LocalAuthenticationMethod) -> Void = { [weak self] newMethod in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await updateMethod(newMethod)
                } catch {
                    handle(error: error)
                }
            }
        }
        let view = LocalAuthenticationMethodsView(selectedMethod: preferences.localAuthenticationMethod,
                                                  supportedMethods: supportedMethods,
                                                  onSelect: { update($0.method) })
        let height = OptionRowHeight.compact.value * CGFloat(supportedMethods.count) + 60

        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .customSheetWithGrabber(CGFloat(height)),
                                                 presentationOption: .none)
    }

    func editAppLockTime() {
        showListOfAppLockTimes()
    }

    func editPINCode() {
        verifyAndThenUpdatePIN()
    }
}

// MARK: - Private APIs

private extension SecuritySettingsCoordinator {
    func updateMethod(_ newMethod: LocalAuthenticationMethod) async throws {
        let currentMethod = preferences.localAuthenticationMethod
        let authenticatingPolicy = preferences.localAuthenticationPolicy
        switch (currentMethod, newMethod) {
        case (.biometric, .biometric),
             (.none, .none),
             (.pin, .pin):
            // No changes, just dismiss the method list & do nothing
            delegate?.childCoordinatorWantsToDismissTopViewController()

        case (.none, .biometric):
            // Enable biometric authentication
            try await biometricallyAuthenticateAndUpdateMethod(newMethod,
                                                               policy: enablingPolicy)

        case (.biometric, .none),
             (.biometric, .pin):
            // Disable biometric authentication or change from biometric to PIN
            try await biometricallyAuthenticateAndUpdateMethod(newMethod,
                                                               policy: authenticatingPolicy)

        case (.none, .pin):
            // Enable PIN authentication
            definePINCodeAndChangeToPINMethod()

        case (.pin, .biometric),
             (.pin, .none):
            // Disable PIN authentication or change from PIN to biometric
            try await verifyPINCodeAndUpdateMethod(newMethod)
        }
    }

    func biometricallyAuthenticateAndUpdateMethod(_ newMethod: LocalAuthenticationMethod,
                                                  policy: LAPolicy) async throws {
        let succesHandler: () async throws -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorWantsToDismissTopViewController()

            if newMethod != .biometric {
                try await updateSharedPreferences(\.fallbackToPasscode, value: true)
            }

            if newMethod == .pin {
                definePINCodeAndChangeToPINMethod()
            } else {
                try await updateSharedPreferences(\.localAuthenticationMethod, value: newMethod)
            }
        }

        delegate?.childCoordinatorWantsToDismissTopViewController()
        let authenticate = try await authenticate(policy: policy,
                                                  reason: #localized("Please authenticate"))
        if authenticate {
            try await succesHandler()
        } else {
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }
    }

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

    func updateAppLockTime(_ newValue: AppLockTime) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateSharedPreferences(\.appLockTime, value: newValue)
                delegate?.childCoordinatorWantsToDismissTopViewController()
            } catch {
                handle(error: error)
            }
        }
    }

    func definePINCodeAndChangeToPINMethod() {
        router.present(for: .setPINCode)
    }

    func verifyPINCodeAndUpdateMethod(_ newMethod: LocalAuthenticationMethod) async throws {
        let successHandler: () async throws -> Void = { [weak self] in
            guard let self else { return }
            delegate?.childCoordinatorWantsToDismissTopViewController()
            try await updateSharedPreferences(\.localAuthenticationMethod, value: newMethod)
        }

        let failureHandler: (String?) -> Void = { [weak self] _ in
            guard let self else { return }
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }

        let view = LocalAuthenticationView(mode: .pin,
                                           onAuth: {},
                                           onSuccess: successHandler,
                                           onFailure: failureHandler)
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .fullScreen,
                                                 presentationOption: .dismissTopViewController)
    }

    func verifyAndThenUpdatePIN() {
        let successHandler: () -> Void = { [weak self] in
            guard let self else { return }
            definePINCodeAndChangeToPINMethod()
        }

        let failureHandler: (String?) -> Void = { [weak self] _ in
            guard let self else { return }
            delegate?.childCoordinatorDidFailLocalAuthentication()
        }

        let view = LocalAuthenticationView(mode: .pin,
                                           onAuth: {},
                                           onSuccess: successHandler,
                                           onFailure: failureHandler)
        delegate?.childCoordinatorWantsToPresent(view: view,
                                                 viewOption: .fullScreen,
                                                 presentationOption: .dismissTopViewController)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
