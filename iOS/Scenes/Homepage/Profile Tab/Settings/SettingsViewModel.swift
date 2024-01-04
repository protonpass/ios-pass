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
import Entities
import Factory
import SwiftUI

@MainActor
protocol SettingsViewModelDelegate: AnyObject {
    func settingsViewModelWantsToGoBack()
    func settingsViewModelWantsToEditDefaultBrowser()
    func settingsViewModelWantsToEditTheme()
    func settingsViewModelWantsToEditClipboardExpiration()
    func settingsViewModelWantsToClearLogs()
}

@MainActor
final class SettingsViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let isShownAsSheet: Bool
    private let favIconRepository = resolve(\SharedRepositoryContainer.favIconRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let syncEventLoop: SyncEventLoopActionProtocol = resolve(\SharedServiceContainer.syncEventLoop)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)

    @Published private(set) var selectedBrowser: Browser
    @Published private(set) var selectedTheme: Theme
    @Published private(set) var selectedClipboardExpiration: ClipboardExpiration

    @Published var displayFavIcons: Bool {
        didSet {
            preferences.displayFavIcons = displayFavIcons
            if !displayFavIcons {
                emptyFavIconCache()
            }
        }
    }

    @Published var shareClipboard: Bool { didSet { preferences.shareClipboard = shareClipboard } }

    weak var delegate: SettingsViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(isShownAsSheet: Bool) {
        self.isShownAsSheet = isShownAsSheet
        selectedBrowser = preferences.browser
        selectedTheme = preferences.theme
        selectedClipboardExpiration = preferences.clipboardExpiration
        displayFavIcons = preferences.displayFavIcons
        shareClipboard = preferences.shareClipboard

        setup()
    }
}

// MARK: - Public APIs

extension SettingsViewModel {
    func goBack() {
        delegate?.settingsViewModelWantsToGoBack()
    }

    func editDefaultBrowser() {
        delegate?.settingsViewModelWantsToEditDefaultBrowser()
    }

    func editTheme() {
        delegate?.settingsViewModelWantsToEditTheme()
    }

    func editClipboardExpiration() {
        delegate?.settingsViewModelWantsToEditClipboardExpiration()
    }

    func viewHostAppLogs() {
        router.present(for: .logView(module: .hostApp))
    }

    func viewAutoFillExensionLogs() {
        router.present(for: .logView(module: .autoFillExtension))
    }

    func clearLogs() {
        delegate?.settingsViewModelWantsToClearLogs()
    }

    func forceSync() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                router.present(for: .fullSync)
                syncEventLoop.stop()
                logger.info("Doing full sync")
                try await vaultsManager.fullSync()
                logger.info("Done full sync")
                syncEventLoop.start()
                router.display(element: .successMessage(config: .refresh))
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

// MARK: - Private APIs

private extension SettingsViewModel {
    func setup() {
        preferences
            .objectWillChange
            .sink { [weak self] in
                guard let self else {
                    return
                }
                // These options are changed in other pages by passing a references
                // of Preferences. So we listen to changes and update here.
                selectedBrowser = preferences.browser
                selectedTheme = preferences.theme
                selectedClipboardExpiration = preferences.clipboardExpiration
            }
            .store(in: &cancellables)

        vaultsManager.attach(to: self, storeIn: &cancellables)
    }

    func emptyFavIconCache() {
        Task { [weak self] in
            guard let self else { return }
            do {
                logger.trace("Fav icons are disabled. Removing all cached fav icons")
                try await favIconRepository.emptyCache()
                logger.info("Removed all cached fav icons")
            } catch {
                logger.error(error)
            }
        }
    }
}
