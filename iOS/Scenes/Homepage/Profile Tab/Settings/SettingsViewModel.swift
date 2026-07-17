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
import DIComposition
import Entities
import FactoryKit
import Macro
import Screens
import Stores
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let isShownAsSheet: Bool
    private let favIconRepository = dependency(\RepositoryContainer.favIconRepository)
    private let logger = dependency(\ToolingContainer.logger)
    private let preferencesManager = dependency(\ToolingContainer.preferencesManager)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let indexItemsForSpotlight = dependency(\UseCasesContainer.indexItemsForSpotlight)
    private let getSpotlightVaults = dependency(\UseCasesContainer.getSpotlightVaults)
    private let updateSpotlightVaults = dependency(\UseCasesContainer.updateSpotlightVaults)
    private let getSharedPreferences = dependency(\UseCasesContainer.getSharedPreferences)
    private let updateSharedPreferences = dependency(\UseCasesContainer.updateSharedPreferences)
    private let getUserPreferences = dependency(\UseCasesContainer.getUserPreferences)
    private let updateUserPreferences = dependency(\UseCasesContainer.updateUserPreferences)
    @LazyInjected(\ServiceContainer.userManager) private var userManager
    @LazyInjected(\UseCasesContainer.fullContentSync) private var fullContentSync
    @LazyInjected(\RepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\ServiceContainer.appContentManager) private var appContentManager

    @Published private(set) var selectedBrowser: Browser
    @Published private(set) var selectedTheme: Theme
    @Published private(set) var selectedClipboardExpiration: ClipboardExpiration
    @Published private(set) var plan: Plan?
    @Published private(set) var displayFavIcons: Bool
    @Published private(set) var shareClipboard: Bool
    @Published private(set) var alwaysShowUsernameField: Bool
    @Published private(set) var copyAfterCreatingAlias: Bool
    @Published private(set) var copyAfterCreatingContact: Bool
    @Published private(set) var spotlightEnabled: Bool
    @Published private(set) var spotlightSearchableContent: SpotlightSearchableContent
    @Published private(set) var spotlightSearchableVaults: SpotlightSearchableVaults
    @Published private(set) var spotlightVaults: [Share]?

    private var cancellables = Set<AnyCancellable>()

    var browser: Browser {
        getSharedPreferences().browser
    }

    var theme: Theme {
        getSharedPreferences().theme
    }

    var clipboardExpiration: ClipboardExpiration {
        getSharedPreferences().clipboardExpiration
    }

    init(isShownAsSheet: Bool) {
        self.isShownAsSheet = isShownAsSheet

        let sharedPreferences = getSharedPreferences()
        let userPreferences = getUserPreferences()

        selectedBrowser = sharedPreferences.browser
        selectedTheme = sharedPreferences.theme
        selectedClipboardExpiration = sharedPreferences.clipboardExpiration
        displayFavIcons = sharedPreferences.displayFavIcons
        shareClipboard = sharedPreferences.shareClipboard
        alwaysShowUsernameField = sharedPreferences.alwaysShowUsernameField
        copyAfterCreatingAlias = sharedPreferences.copyAfterCreatingAlias
        copyAfterCreatingContact = sharedPreferences.copyAfterCreatingContact
        spotlightEnabled = userPreferences.spotlightEnabled
        spotlightSearchableContent = userPreferences.spotlightSearchableContent
        spotlightSearchableVaults = userPreferences.spotlightSearchableVaults

        setup()
    }
}

// MARK: - Public APIs

extension SettingsViewModel {
    func update(browser: Browser) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateSharedPreferences(\.browser, value: browser)
            } catch {
                handle(error)
            }
        }
    }

    func update(theme: Theme) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateSharedPreferences(\.theme, value: theme)
            } catch {
                handle(error)
            }
        }
    }

    func update(clipboardExpiration: ClipboardExpiration) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateSharedPreferences(\.clipboardExpiration, value: clipboardExpiration)
            } catch {
                handle(error)
            }
        }
    }

    func toggleDisplayFavIcons() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let newValue = !displayFavIcons
                try await updateSharedPreferences(\.displayFavIcons, value: newValue)
                if !newValue {
                    logger.trace("Fav icons are disabled. Removing all cached fav icons")
                    try await favIconRepository.emptyCache()
                    logger.info("Removed all cached fav icons")
                }
                displayFavIcons = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleAlwaysShowUsernameField() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let newValue = !alwaysShowUsernameField
                try await updateSharedPreferences(\.alwaysShowUsernameField, value: newValue)
                alwaysShowUsernameField = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleCopyAfterCreatingAlias() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let newValue = !copyAfterCreatingAlias
                try await updateSharedPreferences(\.copyAfterCreatingAlias, value: newValue)
                copyAfterCreatingAlias = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleCopyAfterCreatingContact() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let newValue = !copyAfterCreatingContact
                try await updateSharedPreferences(\.copyAfterCreatingContact, value: newValue)
                copyAfterCreatingContact = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleShareClipboard() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let newValue = !shareClipboard
                try await updateSharedPreferences(\.shareClipboard, value: newValue)
                shareClipboard = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleSpotlight() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if !spotlightEnabled, plan?.isFreeUser == true {
                    router.present(for: .upselling(.default))
                    return
                }
                let newValue = !spotlightEnabled
                try await updateUserPreferences(\.spotlightEnabled, value: newValue)
                spotlightEnabled = newValue
                reindexItemsForSpotlight()
            } catch {
                handle(error)
            }
        }
    }

    func editSpotlightSearchableContent() {
        router.present(for: .editSpotlightSearchableContent)
    }

    func editSpotlightSearchableVaults() {
        router.present(for: .editSpotlightSearchableVaults)
    }

    func editSpotlightSearchableSelectedVaults() {
        guard spotlightVaults != nil else { return }
        router.present(for: .editSpotlightVaults)
    }

    func viewHostAppLogs() {
        router.present(for: .logView(module: .hostApp))
    }

    func viewAutoFillExensionLogs() {
        router.present(for: .logView(module: .autoFillExtension))
    }

    func clearLogs() {
        Task { [weak self] in
            guard let self else {
                return
            }
            let modules = PassModule.allCases.map(LogManager.init)
            await modules.asyncForEach { await $0.removeAllLogs() }
            router.display(element: .successMessage(#localized("All logs cleared"), config: nil))
        }
    }

    func forceSync() {
        Task { [weak self] in
            guard let self else { return }
            do {
                router.present(for: .fullSync)
                logger.info("Doing full sync")
                let userId = try await userManager.getActiveUserId()
                await fullContentSync(userId: userId, shouldStopEventLoop: true)
                logger.info("Done full sync")
                router.display(element: .successMessage(config: .refresh))
            } catch {
                handle(error)
            }
        }
    }

    func clearCachedFiles() {
        do {
            let manager = FileManager.default
            let url = manager.temporaryDirectory.appending(path: Constants.Attachment.rootDirectoryName)
            if manager.fileExists(atPath: url.path()) {
                try manager.removeItem(at: url)
            }
            router.display(element: .successMessage(#localized("Downloaded files cleared")))
        } catch {
            handle(error)
        }
    }
}

// MARK: - Private APIs

private extension SettingsViewModel {
    func setup() {
        preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.browser)
            .sink { [weak self] newValue in
                guard let self else { return }
                selectedBrowser = newValue
            }
            .store(in: &cancellables)

        preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.theme)
            .sink { [weak self] newValue in
                guard let self else { return }
                selectedTheme = newValue
            }
            .store(in: &cancellables)

        preferencesManager
            .sharedPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.clipboardExpiration)
            .sink { [weak self] newValue in
                guard let self else { return }
                selectedClipboardExpiration = newValue
            }
            .store(in: &cancellables)

        preferencesManager
            .userPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.spotlightSearchableContent)
            .sink { [weak self] newValue in
                guard let self else { return }
                spotlightSearchableContent = newValue
            }
            .store(in: &cancellables)

        preferencesManager
            .userPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.spotlightSearchableVaults)
            .sink { [weak self] newValue in
                guard let self else { return }
                spotlightSearchableVaults = newValue
            }
            .store(in: &cancellables)

        preferencesManager
            .userPreferencesUpdates
            .filter([\.spotlightSearchableContent, \.spotlightSearchableVaults])
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                reindexItemsForSpotlight()
            }
            .store(in: &cancellables)

        appContentManager.currentSpotlightSelectedVaults
            .receive(on: DispatchQueue.main)
            .dropFirst() // Drop first event when the stream is init
            // Debouncing 1.5 secs because this will trigger expensive database operations
            // and Spotlight indexation
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] vaults in
                guard let self else { return }
                spotlightVaults = vaults
                reindexItemsForSpotlight()
            }
            .store(in: &cancellables)

        accessRepository
            .access
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .compactMap { $0?.access }
            .sink { [weak self] newAccess in
                guard let self else {
                    return
                }
                plan = newAccess.plan
                if newAccess.plan.isFreeUser {
                    spotlightEnabled = false
                }
            }
            .store(in: &cancellables)

        // swiftlint:disable:next todo
        // TODO: maybe change the observable of appContentManager
        appContentManager.attach(to: self, storeIn: &cancellables)
        refreshSpotlightVaults()
    }

    func reindexItemsForSpotlight() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let preferences = getUserPreferences()
                if preferences.spotlightEnabled {
                    if let spotlightVaults {
                        try await updateSpotlightVaults(for: spotlightVaults)
                    }
                }
                try await indexItemsForSpotlight(preferences)
            } catch {
                handle(error)
            }
        }
    }

    func refreshSpotlightVaults() {
        Task { [weak self] in
            guard let self else { return }
            do {
                logger.trace("Refreshing spotlight vaults")
                let vaults = try await getSpotlightVaults()
                spotlightVaults = vaults
                appContentManager.currentSpotlightSelectedVaults.send(vaults)
                logger.trace("Found \(spotlightVaults?.count ?? 0) spotlight vaults")
            } catch {
                handle(error)
            }
        }
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
