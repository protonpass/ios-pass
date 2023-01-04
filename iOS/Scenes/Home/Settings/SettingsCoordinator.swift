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
import SwiftUI
import UIComponents

protocol SettingsCoordinatorDelegate: AnyObject {
    func settingsCoordinatorWantsToDeleteAccount()
    func settingsCoordinatorDidFinishFullSync()
}

final class SettingsCoordinator: Coordinator {
    private let settingsViewModel: SettingsViewModel
    private let logManager: LogManager

    weak var delegate: SettingsCoordinatorDelegate?
    weak var bannerManager: BannerManager?

    init(itemRepository: ItemRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         symmetricKey: SymmetricKey,
         preferences: Preferences,
         logManager: LogManager) {
        self.settingsViewModel = .init(itemRepository: itemRepository,
                                       credentialManager: credentialManager,
                                       symmetricKey: symmetricKey,
                                       preferences: preferences)
        self.logManager = logManager
        super.init()
        self.settingsViewModel.delegate = self
        start()
    }

    private func start() {
        start(with: SettingsView(viewModel: settingsViewModel),
              secondaryView: ItemDetailPlaceholderView { self.popTopViewController(animated: true) })
    }

    private func showDeviceLogs(for type: DeviceLogType) {
        let viewModel = DeviceLogsViewModel(type: type, logManager: logManager)
        viewModel.delegate = self
        let view = DeviceLogsView(viewModel: viewModel)
        present(view)
    }
}

// MARK: - SettingsViewModelDelegate
extension SettingsCoordinator: SettingsViewModelDelegate {
    func settingsViewModelWantsToToggleSidebar() {
        toggleSidebar()
    }

    func settingsViewModelWantsToShowLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToShowLoadingHud()
    }

    func settingsViewModelWantsToHideLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToHideLoadingHud()
    }

    func settingsViewModelWantsToDeleteAccount() {
        delegate?.settingsCoordinatorWantsToDeleteAccount()
    }

    func settingsViewModelWantsToViewLogs() {
        let view = DeviceLogTypesView(onGoBack: { self.popTopViewController(animated: true) },
                                      onSelect: showDeviceLogs)
        push(view)
    }

    func settingsViewModelWantsToOpenSecuritySettings(viewModel: SettingsViewModel) {
        let view = SecuritySettingsView(viewModel: viewModel) { [unowned self] in
            self.popTopViewController(animated: true)
        }
        push(view)
    }

    func settingsViewModelWantsToUpdateClipboardExpiration(viewModel: SettingsViewModel) {
        let view = ClipboardSettingsView(viewModel: viewModel) { [unowned self] in
            self.popTopViewController(animated: true)
        }
        push(view)
    }

    func settingsViewModelWantsToUpdateAutoFill(viewModel: SettingsViewModel) {
        let view = AutoFillSettingsView(viewModel: viewModel) { [unowned self] in
            self.popTopViewController(animated: true)
        }
        push(view)
    }

    func settingsViewModelWantsToUpdateTheme(viewModel: SettingsViewModel) {
        let view = ThemesView(viewModel: viewModel) { [unowned self] in
            self.popTopViewController(animated: true)
        }
        push(view)
    }

    func settingsViewModelWantsToUpdateDefaultBrowser(viewModel: SettingsViewModel) {
        let view = BrowserSettingsView(viewModel: viewModel) { [unowned self] in
            self.popTopViewController(animated: true)
        }
        push(view)
    }

    func settingsViewModelDidFinishFullSync() {
        delegate?.settingsCoordinatorDidFinishFullSync()
    }

    func settingsViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - DeviceLogsViewModelDelegate
extension SettingsCoordinator: DeviceLogsViewModelDelegate {
    func deviceLogsViewModelWantsToShareLogs(_ url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController)
    }

    func deviceLogsViewModelDidFail(error: Error) {
        alertError(error)
    }
}
