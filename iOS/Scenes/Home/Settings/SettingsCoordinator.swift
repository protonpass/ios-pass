//
// SettingsCoordinator.swift
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
import UIComponents

protocol SettingsCoordinatorDelegate: AnyObject {
    func settingsCoordinatorDidFinishFullSync()
}

final class SettingsCoordinator: Coordinator {
    private let settingsViewModel: SettingsViewModel

    weak var delegate: SettingsCoordinatorDelegate?
    weak var bannerManager: BannerManager?
    var onDeleteAccount: (() -> Void)?

    init(itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         symmetricKey: SymmetricKey,
         preferences: Preferences) {
        self.settingsViewModel = .init(itemRepository: itemRepository,
                                       credentialManager: credentialManager,
                                       symmetricKey: symmetricKey,
                                       preferences: preferences)
        super.init()
        self.settingsViewModel.delegate = self
        start()
    }

    private func start() {
        settingsViewModel.onToggleSidebar = { [unowned self] in
            toggleSidebar()
        }
        settingsViewModel.onDeleteAccount = { [unowned self] in
            onDeleteAccount?()
        }
        start(with: SettingsView(viewModel: settingsViewModel),
              secondaryView: ItemDetailPlaceholderView { self.popTopViewController(animated: true) })
    }
}

// MARK: - SettingsViewModelDelegate
extension SettingsCoordinator: SettingsViewModelDelegate {
    func settingsViewModelWantsToShowLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToShowLoadingHud()
    }

    func settingsViewModelWantsToHideLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToHideLoadingHud()
    }

    func settingsViewModelDidFinishFullSync() {
        delegate?.settingsCoordinatorDidFinishFullSync()
    }

    func settingsViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}
