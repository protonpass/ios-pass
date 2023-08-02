//
// ProfileTabViewModel.swift
// Proton Pass - Created on 07/03/2023.
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

import Client
import Combine
import Core
import Factory
import ProtonCore_Services
import SwiftUI

protocol ProfileTabViewModelDelegate: AnyObject {
    func profileTabViewModelWantsToShowSpinner()
    func profileTabViewModelWantsToHideSpinner()
    func profileTabViewModelWantsToUpgrade()
    func profileTabViewModelWantsToShowAccountMenu()
    func profileTabViewModelWantsToShowSettingsMenu()
    func profileTabViewModelWantsToShowAcknowledgments()
    func profileTabViewModelWantsToShowPrivacyPolicy()
    func profileTabViewModelWantsToShowTermsOfService()
    func profileTabViewModelWantsToShowImportInstructions()
    func profileTabViewModelWantsToShowFeedback()
    func profileTabViewModelWantsToQaFeatures()
    func profileTabViewModelDidEncounter(error: Error)
}

final class ProfileTabViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let credentialManager = resolve(\SharedServiceContainer.credentialManager)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)
    private let passPlanRepository = resolve(\SharedRepositoryContainer.passPlanRepository)
    private let notificationService = resolve(\SharedServiceContainer.notificationService)
    private let securitySettingsCoordinator: SecuritySettingsCoordinator

    private let policy = resolve(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private let checkBiometryType = resolve(\SharedUseCasesContainer.checkBiometryType)

    // Use cases
    private let refreshFeatureFlags = resolve(\UseCasesContainer.refreshFeatureFlags)

    @Published private(set) var localAuthenticationMethod: LocalAuthenticationMethodUiModel = .none
    @Published private(set) var appLockTime: AppLockTime = .twoMinutes
    @Published var fallbackToPasscode = true {
        didSet {
            preferences.fallbackToPasscode = fallbackToPasscode
        }
    }

    /// Whether user has picked Proton Pass as AutoFill provider in Settings
    @Published private(set) var autoFillEnabled: Bool
    @Published var quickTypeBar: Bool { didSet { populateOrRemoveCredentials() } }
    @Published var automaticallyCopyTotpCode: Bool {
        didSet {
            if automaticallyCopyTotpCode {
                notificationService.requestNotificationPermission()
            }
            preferences.automaticallyCopyTotpCode = automaticallyCopyTotpCode
        }
    }

    @Published private(set) var plan: PassPlan?

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: ProfileTabViewModelDelegate?

    init(childCoordinatorDelegate: ChildCoordinatorDelegate) {
        let securitySettingsCoordinator = SecuritySettingsCoordinator()
        securitySettingsCoordinator.delegate = childCoordinatorDelegate
        self.securitySettingsCoordinator = securitySettingsCoordinator

        autoFillEnabled = false
        quickTypeBar = preferences.quickTypeBar
        automaticallyCopyTotpCode = preferences.automaticallyCopyTotpCode

        refresh()

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        preferences.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateAutoFillAvalability()
                self?.updateSecuritySettings()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public APIs

extension ProfileTabViewModel {
    func upgrade() {
        delegate?.profileTabViewModelWantsToUpgrade()
    }

    func refreshPlan() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // First get local plan to optimistically display it
            // and then try to refresh the plan to have it updated
            self.plan = try await self.passPlanRepository.getPlan()
            self.plan = try await self.passPlanRepository.refreshPlan()
        }
    }

    func editLocalAuthenticationMethod() {
        securitySettingsCoordinator.editMethod()
    }

    func editAppLockTime() {
        securitySettingsCoordinator.editAppLockTime()
    }

    func editPINCode() {
        securitySettingsCoordinator.editPINCode()
    }

    func showAccountMenu() {
        delegate?.profileTabViewModelWantsToShowAccountMenu()
    }

    func showSettingsMenu() {
        delegate?.profileTabViewModelWantsToShowSettingsMenu()
    }

    func showAcknowledgments() {
        delegate?.profileTabViewModelWantsToShowAcknowledgments()
    }

    func showPrivacyPolicy() {
        delegate?.profileTabViewModelWantsToShowPrivacyPolicy()
    }

    func showTermsOfService() {
        delegate?.profileTabViewModelWantsToShowTermsOfService()
    }

    func showImportInstructions() {
        delegate?.profileTabViewModelWantsToShowImportInstructions()
    }

    func showFeedback() {
        delegate?.profileTabViewModelWantsToShowFeedback()
    }

    func qaFeatures() {
        delegate?.profileTabViewModelWantsToQaFeatures()
    }
}

// MARK: - Private APIs

private extension ProfileTabViewModel {
    func refresh() {
        updateAutoFillAvalability()
        updateSecuritySettings()
        refreshPlan()
        refreshFeatureFlags()
    }

    func updateSecuritySettings() {
        switch preferences.localAuthenticationMethod {
        case .none:
            localAuthenticationMethod = .none
        case .biometric:
            do {
                let biometryType = try checkBiometryType(policy: policy)
                localAuthenticationMethod = .biometric(biometryType)
            } catch {
                // Fallback to `none`, not much we can do except displaying the error
                logger.error(error)
                delegate?.profileTabViewModelDidEncounter(error: error)
                localAuthenticationMethod = .none
            }
        case .pin:
            localAuthenticationMethod = .pin
        }

        appLockTime = preferences.appLockTime

        if preferences.fallbackToPasscode != fallbackToPasscode {
            // Check before assigning because `fallbackToPasscode` has a `didSet` block
            // that updates preferences hence trigger an infinitely loop
            fallbackToPasscode = preferences.fallbackToPasscode
        }
    }

    func updateAutoFillAvalability() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.autoFillEnabled = await self.credentialManager.isAutoFillEnabled()
        }
    }

    func populateOrRemoveCredentials() {
        // When not enabled, iOS already deleted the credential database.
        // Atempting to populate this database will throw an error anyway so early exit here
        guard autoFillEnabled else { return }

        guard quickTypeBar != preferences.quickTypeBar else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.delegate?.profileTabViewModelWantsToHideSpinner() }
            do {
                self.logger.trace("Updating credential database QuickTypeBar \(self.quickTypeBar)")
                self.delegate?.profileTabViewModelWantsToShowSpinner()
                if self.quickTypeBar {
                    try await self.credentialManager.insertAllCredentials(
                        itemRepository: self.itemRepository,
                        shareRepository: self.shareRepository,
                        passPlanRepository: self.passPlanRepository,
                        forceRemoval: true)
                    self.logger.info("Populated credential database QuickTypeBar \(self.quickTypeBar)")
                } else {
                    try await self.credentialManager.removeAllCredentials()
                    self.logger.info("Nuked credential database QuickTypeBar \(self.quickTypeBar)")
                }
                self.preferences.quickTypeBar = self.quickTypeBar
            } catch {
                self.logger.error(error)
                self.quickTypeBar.toggle() // rollback to previous value
                self.delegate?.profileTabViewModelDidEncounter(error: error)
            }
        }
    }
}
