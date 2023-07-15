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

    private let credentialManager: CredentialManagerProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let logger = Logger(manager: resolve(\SharedToolingContainer.logManager))
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol
    private let passPlanRepository: PassPlanRepositoryProtocol
    private let notificationService: LocalNotificationServiceProtocol
    private let securitySettingsCoordinator: SecuritySettingsCoordinator
    let vaultsManager: VaultsManager

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

    init(credentialManager: CredentialManagerProtocol,
         itemRepository: ItemRepositoryProtocol,
         shareRepository: ShareRepositoryProtocol,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol,
         passPlanRepository: PassPlanRepositoryProtocol,
         vaultsManager: VaultsManager,
         notificationService: LocalNotificationServiceProtocol,
         childCoordinatorDelegate: ChildCoordinatorDelegate) {
        self.credentialManager = credentialManager
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.featureFlagsRepository = featureFlagsRepository
        self.passPlanRepository = passPlanRepository
        self.vaultsManager = vaultsManager
        self.notificationService = notificationService

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
        Task { @MainActor in
            // First get local plan to optimistically display it
            // and then try to refresh the plan to have it updated
            plan = try await passPlanRepository.getPlan()
            plan = try await passPlanRepository.refreshPlan()
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

    func refreshFeatureFlags() {
        Task { @MainActor in
            do {
                let flags = try await featureFlagsRepository.getFlags()
            } catch {
                logger.error(error)
            }
        }
    }

    func updateSecuritySettings() {
        switch preferences.localAuthenticationMethod {
        case .none:
            localAuthenticationMethod = .none
        case .biometric:
            do {
                let policy = resolve(\SharedToolingContainer.localAuthenticationCheckingPolicy)
                let checkBiometryType = resolve(\SharedUseCasesContainer.checkBiometryType)
                let biometryType = try checkBiometryType(for: policy)
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
        Task { @MainActor in
            self.autoFillEnabled = await credentialManager.isAutoFillEnabled()
        }
    }

    func populateOrRemoveCredentials() {
        // When not enabled, iOS already deleted the credential database.
        // Atempting to populate this database will throw an error anyway so early exit here
        guard autoFillEnabled else { return }

        guard quickTypeBar != preferences.quickTypeBar else { return }
        Task { @MainActor in
            defer { delegate?.profileTabViewModelWantsToHideSpinner() }
            do {
                logger.trace("Updating credential database QuickTypeBar \(quickTypeBar)")
                delegate?.profileTabViewModelWantsToShowSpinner()
                if quickTypeBar {
                    try await credentialManager.insertAllCredentials(itemRepository: itemRepository,
                                                                     shareRepository: shareRepository,
                                                                     passPlanRepository: passPlanRepository,
                                                                     forceRemoval: true)
                    logger.info("Populated credential database QuickTypeBar \(quickTypeBar)")
                } else {
                    try await credentialManager.removeAllCredentials()
                    logger.info("Nuked credential database QuickTypeBar \(quickTypeBar)")
                }
                preferences.quickTypeBar = quickTypeBar
            } catch {
                logger.error(error)
                quickTypeBar.toggle() // rollback to previous value
                delegate?.profileTabViewModelDidEncounter(error: error)
            }
        }
    }
}
