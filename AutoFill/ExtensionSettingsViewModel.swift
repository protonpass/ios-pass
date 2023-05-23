//
// ExtensionSettingsViewModel.swift
// Proton Pass - Created on 05/04/2023.
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
import Core
import UserNotifications

protocol ExtensionSettingsViewModelDelegate: AnyObject {
    func extensionSettingsViewModelWantsToShowSpinner()
    func extensionSettingsViewModelWantsToHideSpinner()
    func extensionSettingsViewModelWantsToDismiss()
    func extensionSettingsViewModelWantsToLogOut()
    func extensionSettingsViewModelDidEncounter(error: Error)
}

final class ExtensionSettingsViewModel: ObservableObject {
    @Published var quickTypeBar: Bool { didSet { populateOrRemoveCredentials() } }
    @Published var automaticallyCopyTotpCode: Bool {
        didSet {
            if automaticallyCopyTotpCode {
                requestNotificationPermission()
            }
            preferences.automaticallyCopyTotpCode = automaticallyCopyTotpCode
        }
    }

    @Published var isLocked: Bool

    let credentialManager: CredentialManagerProtocol
    let itemRepository: ItemRepositoryProtocol
    let shareRepository: ShareRepositoryProtocol
    let passPlanRepository: PassPlanRepositoryProtocol
    let logger: Logger
    let logManager: LogManager
    let preferences: Preferences

    weak var delegate: ExtensionSettingsViewModelDelegate?

    init(credentialManager: CredentialManagerProtocol,
         itemRepository: ItemRepositoryProtocol,
         shareRepository: ShareRepositoryProtocol,
         passPlanRepository: PassPlanRepositoryProtocol,
         logManager: LogManager,
         preferences: Preferences) {
        self.credentialManager = credentialManager
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.passPlanRepository = passPlanRepository
        self.logManager = logManager
        self.logger = .init(manager: logManager)
        self.preferences = preferences

        self.quickTypeBar = preferences.quickTypeBar
        self.automaticallyCopyTotpCode = preferences.automaticallyCopyTotpCode
        self.isLocked = preferences.biometricAuthenticationEnabled
    }
}

// MARK: - Public APIs
extension ExtensionSettingsViewModel {
    func dismiss() {
        delegate?.extensionSettingsViewModelWantsToDismiss()
    }

    func logOut() {
        delegate?.extensionSettingsViewModelWantsToLogOut()
    }
}

// MARK: - Private APIs
private extension ExtensionSettingsViewModel {
    func populateOrRemoveCredentials() {
        guard quickTypeBar != preferences.quickTypeBar else { return }
        Task { @MainActor in
            defer { delegate?.extensionSettingsViewModelWantsToHideSpinner() }
            do {
                logger.trace("Updating credential database QuickTypeBar \(quickTypeBar)")
                delegate?.extensionSettingsViewModelWantsToShowSpinner()
                if quickTypeBar {
                    try await credentialManager.insertAllCredentials(
                        itemRepository: itemRepository,
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
                delegate?.extensionSettingsViewModelDidEncounter(error: error)
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { _, _ in }
    }
}
