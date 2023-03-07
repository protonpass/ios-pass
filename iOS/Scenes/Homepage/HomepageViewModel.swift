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
import Core
import CryptoKit
import ProtonCore_Login

protocol HomepageViewModelDelegate: AnyObject {
    func homepageViewModelWantsToCreateNewItem()
    func homepageViewModelWantsToSearch()
    func homepageViewModelWantsToPresentVaultList()
}

final class HomepageViewModel: DeinitPrintable {
    deinit { print(deinitMessage) }

    let vaultsManager: VaultsManager
    let itemsTabViewModel: ItemsTabViewModel

    weak var delegate: HomepageViewModelDelegate?

    init(itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         shareRepository: ShareRepositoryProtocol,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        self.vaultsManager = .init(itemRepository: itemRepository,
                                   logManager: logManager,
                                   shareRepository: shareRepository,
                                   symmetricKey: symmetricKey,
                                   userData: userData)
        self.itemsTabViewModel = .init()
        self.itemsTabViewModel.delegate = self
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
