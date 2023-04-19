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
import ProtonCore_Services
import SwiftUI

protocol ProfileTabViewModelDelegate: AnyObject {
    func profileTabViewModelWantsToShowSpinner()
    func profileTabViewModelWantsToHideSpinner()
    func profileTabViewModelWantsToShowAccountMenu()
    func profileTabViewModelWantsToShowSettingsMenu()
    func profileTabViewModelWantsToShowAcknowledgments()
    func profileTabViewModelWantsToShowPrivacyPolicy()
    func profileTabViewModelWantsToShowTermsOfService()
    func profileTabViewModelWantsToShowTips()
    func profileTabViewModelWantsToShowFeedback()
    func profileTabViewModelWantsToRateApp()
    func profileTabViewModelWantsToQaFeatures()
    func profileTabViewModelWantsDidEncounter(error: Error)
}

final class ProfileTabViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let apiService: APIService
    var biometricAuthenticator: BiometricAuthenticator
    let credentialManager: CredentialManagerProtocol
    let itemRepository: ItemRepositoryProtocol
    let logger: Logger
    let preferences: Preferences
    let appVersion: String
    let vaultsManager: VaultsManager

    /// Whether user has picked Proton Pass as AutoFill provider in Settings
    @Published private(set) var autoFillEnabled: Bool { didSet { populateOrRemoveCredentials() } }
    @Published var quickTypeBar: Bool { didSet { populateOrRemoveCredentials() } }
    @Published var automaticallyCopyTotpCode: Bool {
        didSet {
            if automaticallyCopyTotpCode {
                requestNotificationPermission()
            }
            preferences.automaticallyCopyTotpCode = automaticallyCopyTotpCode
        }
    }

    @Published private(set) var primaryPlan: PlanLite?

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: ProfileTabViewModelDelegate?

    init(apiService: APIService,
         credentialManager: CredentialManagerProtocol,
         itemRepository: ItemRepositoryProtocol,
         primaryPlan: PlanLite?,
         preferences: Preferences,
         logManager: LogManager,
         vaultsManager: VaultsManager) {
        self.apiService = apiService
        self.biometricAuthenticator = .init(preferences: preferences, logManager: logManager)
        self.credentialManager = credentialManager
        self.itemRepository = itemRepository
        self.logger = .init(manager: logManager)
        self.primaryPlan = primaryPlan
        self.preferences = preferences
        self.appVersion = "Version \(Bundle.main.fullAppVersionName()) (\(Bundle.main.buildNumber))"
        self.vaultsManager = vaultsManager

        self.autoFillEnabled = false
        self.quickTypeBar = preferences.quickTypeBar
        self.automaticallyCopyTotpCode = preferences.automaticallyCopyTotpCode

        self.biometricAuthenticator.attach(to: self, storeIn: &cancellables)
        self.refresh()

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        biometricAuthenticator.$authenticationState
            .sink { [weak self] state in
                guard let self else { return }
                if case let .error(error) = state {
                    self.delegate?.profileTabViewModelWantsDidEncounter(error: error)
                }
            }
            .store(in: &cancellables)

        preferences.objectWillChange
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Public APIs
extension ProfileTabViewModel {
    func upgrade() {
        print(#function)
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

    func showTips() {
        delegate?.profileTabViewModelWantsToShowTips()
    }

    func showFeedback() {
        delegate?.profileTabViewModelWantsToShowFeedback()
    }

    func rateApp() {
        delegate?.profileTabViewModelWantsToRateApp()
    }

    func qaFeatures() {
        delegate?.profileTabViewModelWantsToQaFeatures()
    }
}

// MARK: - Private APIs
private extension ProfileTabViewModel {
    func refresh() {
        updateAutoFillAvalability()
        biometricAuthenticator.initializeBiometryType()
        biometricAuthenticator.enabled = preferences.biometricAuthenticationEnabled
        Task { @MainActor in
            primaryPlan = try await PrimaryPlanProvider.getPrimaryPlan(apiService: apiService).value
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
                    try await credentialManager.insertAllCredentials(from: itemRepository,
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
                delegate?.profileTabViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }
}