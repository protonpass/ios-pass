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

final class SettingsCoordinator: Coordinator {
    private let settingsViewModel: SettingsViewModel

    init(itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         symmetricKey: SymmetricKey) {
        self.settingsViewModel = .init(itemRepository: itemRepository,
                                       credentialManager: credentialManager,
                                       symmetricKey: symmetricKey)
        super.init()
        start()
    }

    private func start() {
        settingsViewModel.delegate = self
        settingsViewModel.onToggleSidebar = { [unowned self] in
            toggleSidebar()
        }
        start(with: SettingsView(viewModel: settingsViewModel))
    }
}

// MARK: - BaseViewModelDelegate
extension SettingsCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() { showLoadingHud() }

    func viewModelStopsLoading() { hideLoadingHud() }

    func viewModelDidFailWithError(_ error: Error) { alertError(error) }
}
