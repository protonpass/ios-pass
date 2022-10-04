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
import Core
import CryptoKit
import SwiftUI

public enum SettingsKeys {
    public static let quickTypeBar = "quickTypeBar"
}

final class SettingsViewModel: BaseViewModel, DeinitPrintable, ObservableObject {
    private let itemRepository: ItemRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let symmetricKey: SymmetricKey

    // Use a temporary boolean here because enabling/disabling can throw errors
    // and when errors happen, we can rollback this boolean
    @Published var tempQuickTypeBar = true {
        didSet {
            populateOrRemoveCredentials()
        }
    }
    @AppStorage(SettingsKeys.quickTypeBar) private var quickTypeBar = true

    /// Whether user has picked Proton Pass as AutoFill provider in Settings
    @Published private(set) var autoFillEnabled = false {
        didSet {
            populateOrRemoveCredentials()
        }
    }

    var onToggleSidebar: (() -> Void)?

    init(itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         symmetricKey: SymmetricKey) {
        self.itemRepository = itemRepository
        self.credentialManager = credentialManager
        self.symmetricKey = symmetricKey
        super.init()
        self.tempQuickTypeBar = quickTypeBar
        self.updateAutoFillAvalability()

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.updateAutoFillAvalability()
            }
            .store(in: &cancellables)
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

        guard tempQuickTypeBar != quickTypeBar else { return }
        Task { @MainActor in
            defer { isLoading = false }
            do {
                isLoading = true
                if tempQuickTypeBar {
                    try await credentialManager.insertAllCredentials(from: itemRepository,
                                                                     symmetricKey: symmetricKey,
                                                                     forceRemoval: true)
                } else {
                    try await credentialManager.removeAllCredentials()
                }
                quickTypeBar = tempQuickTypeBar
            } catch {
                self.tempQuickTypeBar.toggle() // rollback to previous value
                self.error = error
            }
        }
    }
}

// MARK: - Actions
extension SettingsViewModel {
    func toggleSidebar() { onToggleSidebar?() }
}
