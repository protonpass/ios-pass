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
    func homepageViewModelWantsToCreateNewItem()
    func homepageViewModelWantsToSearch()
    func homepageViewModelWantsToPresentVaultList()
}

final class HomepageViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let itemsTabViewModel: ItemsTabViewModel
    let preferences: Preferences
    let vaultsManager: VaultsManager

    weak var delegate: HomepageViewModelDelegate?

    private var cancellables = Set<AnyCancellable>()

    init(itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         preferences: Preferences,
         shareRepository: ShareRepositoryProtocol,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        self.itemsTabViewModel = .init()
        self.preferences = preferences
        self.vaultsManager = .init(itemRepository: itemRepository,
                                   logManager: logManager,
                                   shareRepository: shareRepository,
                                   symmetricKey: symmetricKey,
                                   userData: userData)
        self.finalizeInitialization()
    }
}

// MARK: - Private APIs
private extension HomepageViewModel {
    func finalizeInitialization() {
        itemsTabViewModel.delegate = self
        preferences.attach(to: self, storeIn: &cancellables)
    }
}

// MARK: - Public APIs
extension HomepageViewModel {
    func createNewItem() {
        delegate?.homepageViewModelWantsToCreateNewItem()
    }
}

// MARK: - ItemsTabViewModelDelegate
extension HomepageViewModel: ItemsTabViewModelDelegate {
    func itemsTabViewModelWantsToSearch() {
        delegate?.homepageViewModelWantsToSearch()
    }

    func itemsTabViewModelWantsToPresentVaultList() {
        delegate?.homepageViewModelWantsToPresentVaultList()
    }
}
