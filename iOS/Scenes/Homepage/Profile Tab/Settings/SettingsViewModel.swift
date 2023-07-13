//
// SettingsViewModel.swift
// Proton Pass - Created on 31/03/2023.
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
import SwiftUI

protocol SettingsViewModelDelegate: AnyObject {
    func settingsViewModelWantsToShowSpinner()
    func settingsViewModelWantsToHideSpinner()
    func settingsViewModelWantsToGoBack()
    func settingsViewModelWantsToEditDefaultBrowser(supportedBrowsers: [Browser])
    func settingsViewModelWantsToEditTheme()
    func settingsViewModelWantsToEditClipboardExpiration()
    func settingsViewModelWantsToEdit(primaryVault: Vault)
    func settingsViewModelWantsToViewHostAppLogs()
    func settingsViewModelWantsToViewAutoFillExtensionLogs()
    func settingsViewModelWantsToClearLogs()
    func settingsViewModelDidDisableFavIcons()
    func settingsViewModelDidFinishFullSync()
    func settingsViewModelDidEncounter(error: Error)
}

final class SettingsViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let isShownAsSheet: Bool
    private let logger: Logger
    private let preferences: Preferences
    private let syncEventLoop: SyncEventLoopActionProtocol
    let vaultsManager: VaultsManager

    let supportedBrowsers: [Browser]
    @Published private(set) var selectedBrowser: Browser
    @Published private(set) var selectedTheme: Theme
    @Published private(set) var selectedClipboardExpiration: ClipboardExpiration
    @Published var displayFavIcons: Bool {
        didSet {
            preferences.displayFavIcons = displayFavIcons
            if !displayFavIcons {
                delegate?.settingsViewModelDidDisableFavIcons()
            }
        }
    }

    @Published var shareClipboard: Bool { didSet { preferences.shareClipboard = shareClipboard } }

    weak var delegate: SettingsViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(isShownAsSheet: Bool,
         logManager: LogManagerProtocol,
         preferences: Preferences,
         vaultsManager: VaultsManager,
         syncEventLoop: SyncEventLoopActionProtocol) {
        self.isShownAsSheet = isShownAsSheet
        logger = .init(manager: logManager)
        self.preferences = preferences
        self.syncEventLoop = syncEventLoop

        let installedBrowsers = Browser.thirdPartyBrowsers.filter { browser in
            guard let appScheme = browser.appScheme,
                  let testUrl = URL(string: appScheme + "proton.me") else {
                return false
            }
            return UIApplication.shared.canOpenURL(testUrl)
        }

        switch preferences.browser {
        case .inAppSafari, .safari:
            selectedBrowser = preferences.browser
        default:
            if installedBrowsers.contains(preferences.browser) {
                selectedBrowser = preferences.browser
            } else {
                selectedBrowser = .safari
            }
        }

        supportedBrowsers = [.safari, .inAppSafari] + installedBrowsers

        selectedTheme = preferences.theme
        selectedClipboardExpiration = preferences.clipboardExpiration
        displayFavIcons = preferences.displayFavIcons
        shareClipboard = preferences.shareClipboard
        self.vaultsManager = vaultsManager

        preferences
            .objectWillChange
            .sink { [weak self] in
                guard let self else {
                    return
                }
                // These options are changed in other pages by passing a references
                // of Preferences. So we listen to changes and update here.
                self.selectedBrowser = self.preferences.browser
                self.selectedTheme = self.preferences.theme
                self.selectedClipboardExpiration = self.preferences.clipboardExpiration
            }
            .store(in: &cancellables)

        vaultsManager.attach(to: self, storeIn: &cancellables)
    }
}

// MARK: - Public APIs

extension SettingsViewModel {
    func goBack() {
        delegate?.settingsViewModelWantsToGoBack()
    }

    func editDefaultBrowser() {
        delegate?.settingsViewModelWantsToEditDefaultBrowser(supportedBrowsers: supportedBrowsers)
    }

    func editTheme() {
        delegate?.settingsViewModelWantsToEditTheme()
    }

    func editClipboardExpiration() {
        delegate?.settingsViewModelWantsToEditClipboardExpiration()
    }

    func edit(primaryVault: Vault) {
        delegate?.settingsViewModelWantsToEdit(primaryVault: primaryVault)
    }

    func viewHostAppLogs() {
        delegate?.settingsViewModelWantsToViewHostAppLogs()
    }

    func viewAutoFillExensionLogs() {
        delegate?.settingsViewModelWantsToViewAutoFillExtensionLogs()
    }

    func clearLogs() {
        delegate?.settingsViewModelWantsToClearLogs()
    }

    func forceSync() {
        Task { @MainActor [weak self] in
            defer { self?.delegate?.settingsViewModelWantsToHideSpinner() }
            do {
                self?.syncEventLoop.stop()
                self?.logger.info("Doing full sync")
                self?.delegate?.settingsViewModelWantsToShowSpinner()
                try await self?.vaultsManager.fullSync()
                self?.logger.info("Done full sync")
                self?.syncEventLoop.start()
                self?.delegate?.settingsViewModelDidFinishFullSync()
            } catch {
                self?.logger.error(error)
                self?.delegate?.settingsViewModelDidEncounter(error: error)
            }
        }
    }
}
