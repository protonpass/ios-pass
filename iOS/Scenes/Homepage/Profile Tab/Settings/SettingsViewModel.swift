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
    func settingsViewModelWantsToViewLogs()
    func settingsViewModelDidFinishFullSync()
    func settingsViewModelDidEncounter(error: Error)
}

final class SettingsViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let preferences: Preferences
    let vaultsManager: VaultsManager

    let supportedBrowsers: [Browser]
    @Published private(set) var selectedBrowser: Browser
    @Published private(set) var selectedTheme: Theme
    @Published private(set) var selectedClipboardExpiration: ClipboardExpiration
    @Published var shareClipboard: Bool { didSet { preferences.shareClipboard = shareClipboard } }

    weak var delegate: SettingsViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         preferences: Preferences,
         vaultsManager: VaultsManager) {
        self.itemRepository = itemRepository
        self.logger = .init(manager: logManager)
        self.preferences = preferences

        let installedBrowsers = Browser.thirdPartyBrowsers.filter { browser in
            guard let appScheme = browser.appScheme,
                  let testUrl = URL(string: appScheme + "proton.me") else {
                return false
            }
            return UIApplication.shared.canOpenURL(testUrl)
        }

        switch preferences.browser {
        case .safari, .inAppSafari:
            self.selectedBrowser = preferences.browser
        default:
            if installedBrowsers.contains(preferences.browser) {
                self.selectedBrowser = preferences.browser
            } else {
                self.selectedBrowser = .safari
            }
        }

        self.supportedBrowsers = [.safari, .inAppSafari] + installedBrowsers

        self.selectedTheme = preferences.theme
        self.selectedClipboardExpiration = preferences.clipboardExpiration
        self.shareClipboard = preferences.shareClipboard
        self.vaultsManager = vaultsManager

        preferences
            .objectWillChange
            .sink { [unowned self] in
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

    func viewLogs() {
        delegate?.settingsViewModelWantsToViewLogs()
    }

    func forceSync() {
        Task { @MainActor in
            defer { delegate?.settingsViewModelWantsToHideSpinner() }
            do {
                logger.trace("Doing full sync")
                delegate?.settingsViewModelWantsToShowSpinner()
                try await itemRepository.refreshItems()
                logger.info("Done full sync")
                delegate?.settingsViewModelDidFinishFullSync()
            } catch {
                logger.error(error)
                delegate?.settingsViewModelDidEncounter(error: error)
            }
        }
    }
}
