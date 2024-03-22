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

import Core
import Factory
import UserNotifications

@MainActor
final class ExtensionSettingsViewModel: ObservableObject {
    @Published var quickTypeBar: Bool { didSet { populateOrRemoveCredentials() } }
    @Published var automaticallyCopyTotpCode: Bool {
        didSet {
            if automaticallyCopyTotpCode {
                notificationService.requestNotificationPermission()
            }
            preferences.automaticallyCopyTotpCode = automaticallyCopyTotpCode
        }
    }

    private let logger = resolve(\SharedToolingContainer.logger)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let notificationService = resolve(\SharedServiceContainer.notificationService)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    // Use cases
    private let indexAllLoginItems = resolve(\SharedUseCasesContainer.indexAllLoginItems)
    private let unindexAllLoginItems = resolve(\SharedUseCasesContainer.unindexAllLoginItems)

    init() {
        quickTypeBar = preferences.quickTypeBar
        automaticallyCopyTotpCode = preferences.automaticallyCopyTotpCode
    }
}

// MARK: - Private APIs

private extension ExtensionSettingsViewModel {
    func populateOrRemoveCredentials() {
        guard quickTypeBar != preferences.quickTypeBar else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                logger.trace("Updating credential database QuickTypeBar \(quickTypeBar)")
                router.display(element: .globalLoading(shouldShow: true))
                if quickTypeBar {
                    try await indexAllLoginItems(ignorePreferences: true)
                } else {
                    try await unindexAllLoginItems()
                }
                preferences.quickTypeBar = quickTypeBar
            } catch {
                logger.error(error)
                quickTypeBar.toggle() // rollback to previous value
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
