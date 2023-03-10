//
// HomepageViewModel.swift
// Proton Pass - Created on 06/03/2023.
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
import CryptoKit
import ProtonCore_Login

protocol HomepageViewModelDelegate: AnyObject {
    func homepageViewModelWantsToCreateNewItem(shareId: String)
    func homepageViewModelWantsToLogOut()
}

final class HomepageViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let itemsTabViewModel: ItemsTabViewModel
    let preferences: Preferences
    let profileTabViewModel: ProfileTabViewModel
    let vaultsManager: VaultsManager

    weak var delegate: HomepageViewModelDelegate?
    weak var itemsTabViewModelDelegate: ItemsTabViewModelDelegate? {
        didSet {
            itemsTabViewModel.delegate = itemsTabViewModelDelegate
        }
    }
    private var cancellables = Set<AnyCancellable>()

    init(itemRepository: ItemRepositoryProtocol,
         manualLogIn: Bool,
         logManager: LogManager,
         preferences: Preferences,
         shareRepository: ShareRepositoryProtocol,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        let vaultsManager = VaultsManager(itemRepository: itemRepository,
                                          manualLogIn: manualLogIn,
                                          logManager: logManager,
                                          shareRepository: shareRepository,
                                          symmetricKey: symmetricKey,
                                          userData: userData)
        self.itemsTabViewModel = .init(itemRepository: itemRepository,
                                       logManager: logManager,
                                       preferences: preferences,
                                       vaultsManager: vaultsManager)
        self.preferences = preferences
        self.profileTabViewModel = .init()
        self.vaultsManager = vaultsManager
        self.finalizeInitialization()
    }
}

// MARK: - Private APIs
private extension HomepageViewModel {
    func finalizeInitialization() {
        profileTabViewModel.delegate = self
        preferences.attach(to: self, storeIn: &cancellables)
    }
}

// MARK: - Public APIs
extension HomepageViewModel {
    func createNewItem() {
        delegate?.homepageViewModelWantsToCreateNewItem(shareId: vaultsManager.selectedVault?.shareId ?? "")
    }
}

// MARK: - ProfileTabViewModelDelegate
extension HomepageViewModel: ProfileTabViewModelDelegate {
    func profileTabViewModelWantsToLogOut() {
        delegate?.homepageViewModelWantsToLogOut()
    }
}
