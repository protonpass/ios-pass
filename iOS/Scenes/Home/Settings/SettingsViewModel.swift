//
// SettingsViewModel.swift
// Proton Pass - Created on 28/09/2022.
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
import CryptoKit
import SwiftUI
import UIComponents

protocol SettingsViewModelDelegate: AnyObject {
    func settingsViewModelWantsToToggleSidebar()
    func settingsViewModelWantsToShowLoadingHud()
    func settingsViewModelWantsToHideLoadingHud()
    func settingsViewModelWantsToDeleteAccount()
    func settingsViewModelWantsToOpenSecuritySettings(viewModel: SettingsViewModel)
    func settingsViewModelWantsToUpdateClipboardExpiration(viewModel: SettingsViewModel)
    func settingsViewModelWantsToUpdateAutoFill(viewModel: SettingsViewModel)
    func settingsViewModelWantsToUpdateTheme(viewModel: SettingsViewModel)
    func settingsViewModelWantsToUpdateDefaultBrowser(viewModel: SettingsViewModel)
    func settingsViewModelDidFinishFullSync()
    func settingsViewModelDidFail(_ error: Error)
}

final class SettingsViewModel: DeinitPrintable, ObservableObject {
    private let itemRepository: ItemRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let symmetricKey: SymmetricKey
    let biometricAuthenticator: BiometricAuthenticator
    let preferences: Preferences

    weak var delegate: SettingsViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    @Published var quickTypeBar = true {
        didSet {
            populateOrRemoveCredentials()
        }
    }

    /// Whether user has picked Proton Pass as AutoFill provider in Settings
    @Published private(set) var autoFillEnabled = false {
        didSet {
            populateOrRemoveCredentials()
        }
    }

    @Published var theme: Theme {
        didSet {
            preferences.theme = theme
        }
    }

    @Published private(set) var supportedBrowsers: [Browser]

    @Published var browser: Browser {
        didSet {
            preferences.browser = browser
        }
    }

    @Published var clipboardExpiration: ClipboardExpiration {
        didSet {
            preferences.clipboardExpiration = clipboardExpiration
        }
    }

    @Published var shareClipboard: Bool {
        didSet {
            preferences.shareClipboard = shareClipboard
        }
    }

    init(itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         symmetricKey: SymmetricKey,
         preferences: Preferences) {
        self.itemRepository = itemRepository
        self.credentialManager = credentialManager
        self.symmetricKey = symmetricKey
        self.biometricAuthenticator = .init(preferences: preferences)
        self.preferences = preferences
        self.quickTypeBar = preferences.quickTypeBar
        self.theme = preferences.theme
        self.clipboardExpiration = preferences.clipboardExpiration
        self.shareClipboard = preferences.shareClipboard

        let installedBrowsers = Browser.thirdPartyBrowsers.filter { browser in
            guard let appScheme = browser.appScheme,
                  let testUrl = URL(string: appScheme + "proton.me") else {
                return false
            }
            return UIApplication.shared.canOpenURL(testUrl)
        }

        // Double check selected browser here. If it's no more avaible (uninstalled).
        // Fallback to Safari
        self.browser = installedBrowsers.contains(preferences.browser) ?
        preferences.browser : .safari
        self.supportedBrowsers = [.safari, .inAppSafari] + installedBrowsers

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
                    self.delegate?.settingsViewModelDidFail(error)
                }
            }
            .store(in: &cancellables)

        preferences.objectWillChange
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }

    private func refresh() {
        updateAutoFillAvalability()
        biometricAuthenticator.initializeBiometryType()
        biometricAuthenticator.enabled = preferences.biometricAuthenticationEnabled
    }

    private func updateAutoFillAvalability() {
        Task { @MainActor in
            self.autoFillEnabled = await credentialManager.isAutoFillEnabled()
        }
    }

    private func populateOrRemoveCredentials() {
        // When not enabled, iOS already deleted the credential database.
        // Atempting to populate this database will throw an error anyway so early exit here
        guard autoFillEnabled else { return }

        guard quickTypeBar != preferences.quickTypeBar else { return }
        Task { @MainActor in
            defer { delegate?.settingsViewModelWantsToHideLoadingHud() }
            do {
                delegate?.settingsViewModelWantsToShowLoadingHud()
                if quickTypeBar {
                    try await credentialManager.insertAllCredentials(from: itemRepository,
                                                                     symmetricKey: symmetricKey,
                                                                     forceRemoval: true)
                } else {
                    try await credentialManager.removeAllCredentials()
                }
                preferences.quickTypeBar = quickTypeBar
            } catch {
                quickTypeBar.toggle() // rollback to previous value
                delegate?.settingsViewModelDidFail(error)
            }
        }
    }
}

// MARK: - Actions
extension SettingsViewModel {
    func toggleSidebar() {
        delegate?.settingsViewModelWantsToToggleSidebar()
    }

    func deleteAccount() {
        delegate?.settingsViewModelWantsToDeleteAccount()
    }

    func openSecuritySettings() {
        delegate?.settingsViewModelWantsToOpenSecuritySettings(viewModel: self)
    }

    func updateClipboardExpiration() {
        delegate?.settingsViewModelWantsToUpdateClipboardExpiration(viewModel: self)
    }

    func updateDefaultBrowser() {
        delegate?.settingsViewModelWantsToUpdateDefaultBrowser(viewModel: self)
    }

    func updateAutoFill() {
        delegate?.settingsViewModelWantsToUpdateAutoFill(viewModel: self)
    }

    func fullSync() {
        Task { @MainActor in
            defer { delegate?.settingsViewModelWantsToHideLoadingHud() }
            do {
                delegate?.settingsViewModelWantsToShowLoadingHud()
                /// Does not matter getting `active` or `trashed` items. We only want to force refresh.
                _ = try await itemRepository.getItems(forceRefresh: true, state: .active)
                delegate?.settingsViewModelDidFinishFullSync()
            } catch {
                delegate?.settingsViewModelDidFail(error)
            }
        }
    }

    func updateTheme() {
        delegate?.settingsViewModelWantsToUpdateTheme(viewModel: self)
    }
}
