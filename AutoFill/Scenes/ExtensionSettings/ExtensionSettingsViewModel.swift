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
import DIComposition
import FactoryKit
import Screens
import UserNotifications

@MainActor
final class ExtensionSettingsViewModel: ObservableObject {
    @Published private(set) var quickTypeBar: Bool
    @Published private(set) var automaticallyCopyTotpCode: Bool
    @Published private(set) var showAutomaticCopyTotpCodeExplication = false
    private let logger = dependency(\ToolingContainer.logger)
    private let notificationService = dependency(\ServiceContainer.notificationService)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)

    // Use cases
    private let indexAllLoginItems = dependency(\UseCasesContainer.indexAllLoginItems)
    private let unindexAllLoginItems = dependency(\UseCasesContainer.unindexAllLoginItems)
    private let getSharedPreferences = dependency(\UseCasesContainer.getSharedPreferences)
    private let updateSharedPreferences = dependency(\UseCasesContainer.updateSharedPreferences)

    init() {
        let preferences = getSharedPreferences()
        quickTypeBar = preferences.quickTypeBar
        automaticallyCopyTotpCode = preferences.automaticallyCopyTotpCode && preferences
            .localAuthenticationMethod != .none
    }

    func toggleQuickTypeBar() {
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                let newValue = !quickTypeBar
                async let updateSharedPreferences: () = updateSharedPreferences(\.quickTypeBar,
                                                                                value: newValue)
                async let reindex: () = reindexCredentials(newValue)
                _ = try await (updateSharedPreferences, reindex)
                quickTypeBar = newValue
            } catch {
                handle(error)
            }
        }
    }

    func toggleAutomaticCopy2FACode() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if !automaticallyCopyTotpCode, getSharedPreferences().localAuthenticationMethod == .none {
                    showAutomaticCopyTotpCodeExplication = true
                    return
                }

                let newValue = !automaticallyCopyTotpCode
                if newValue {
                    notificationService.requestNotificationPermission()
                }
                try await updateSharedPreferences(\.automaticallyCopyTotpCode, value: newValue)
                automaticallyCopyTotpCode = newValue
            } catch {
                handle(error)
            }
        }
    }
}

// MARK: - Private APIs

private extension ExtensionSettingsViewModel {
    func reindexCredentials(_ indexable: Bool) async throws {
        logger.trace("Reindexing credentials")
        if indexable {
            try await indexAllLoginItems()
        } else {
            try await unindexAllLoginItems()
        }
        logger.info("Reindexed credentials")
    }

    func handle(_ error: any Error,
                file: String = #file,
                function: String = #function,
                line: UInt = #line,
                column: UInt = #column) {
        logger.error(error, file: file, function: function, line: line, column: column)
        router.display(element: .displayErrorBanner(error))
    }
}
