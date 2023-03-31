//
// ProfileTabViewModel.swift
// Proton Pass - Created on 07/03/2023.
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

protocol ProfileTabViewModelDelegate: AnyObject {
    func profileTabViewModelWantsToShowAccountMenu()
    func profileTabViewModelWantsToShowSettingsMenu()
    func profileTabViewModelWantsToShowAcknowledgments()
    func profileTabViewModelWantsToShowPrivacyPolicy()
    func profileTabViewModelWantsToShowTermsOfService()
}

final class ProfileTabViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    var biometricAuthenticator: BiometricAuthenticator
    let itemCountViewModel: ItemCountViewModel

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: ProfileTabViewModelDelegate?

    init(itemRepository: ItemRepositoryProtocol,
         preferences: Preferences,
         logManager: LogManager) {
        self.biometricAuthenticator = .init(preferences: preferences, logManager: logManager)
        self.itemCountViewModel = .init(itemRepository: itemRepository, logManager: logManager)
        self.biometricAuthenticator.attach(to: self, storeIn: &cancellables)
        self.biometricAuthenticator.initializeBiometryType()
    }
}

// MARK: - Public APIs
extension ProfileTabViewModel {
    func showAccountMenu() {
        delegate?.profileTabViewModelWantsToShowAccountMenu()
    }

    func showSettingsMenu() {
        delegate?.profileTabViewModelWantsToShowSettingsMenu()
    }

    func showAcknowledgments() {
        delegate?.profileTabViewModelWantsToShowAcknowledgments()
    }

    func showPrivacyPolicy() {
        delegate?.profileTabViewModelWantsToShowPrivacyPolicy()
    }

    func showTermsOfService() {
        delegate?.profileTabViewModelWantsToShowTermsOfService()
    }
}
