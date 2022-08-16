//
// VaultContentViewModel.swift
// Proton Pass - Created on 21/07/2022.
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
import Combine
import Core
import ProtonCore_Login
import ProtonCore_UIFoundations
import UIComponents
import UIKit

protocol VaultContentViewModelDelegate: AnyObject {
    func vaultContentViewModelWantsToToggleSidebar()
    func vaultContentViewModelWantsToSearch()
    func vaultContentViewModelWantsToCreateNewItem()
    func vaultContentViewModelWantsToCreateNewVault()
    func vaultContentViewModelDidFailWithError(error: Error)
}

final class VaultContentViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

    @Published private(set) var itemRevisions = [ItemRevision]()
    @Published private(set) var partialItemContents = [PartialItemContent]()

    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let shareRepository: ShareRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: VaultContentViewModelDelegate?

    init(userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol) {
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)

        $itemRevisions
            .sink { [unowned self] newItemRevisions in
                self.decrypt(itemRevisions: newItemRevisions)
            }
            .store(in: &cancellables)
    }

    func update(selectedVault: VaultProtocol?) {
        vaultSelection.update(selectedVault: selectedVault)
    }

    func fetchItems(forceRefresh: Bool = false) {
        guard let shareId = selectedVault?.shareId else { return }
        Task { @MainActor in
            do {
                let itemRevisionList =
                try await itemRevisionRepository.getItemRevisions(forceRefresh: forceRefresh,
                                                                  shareId: shareId,
                                                                  page: 0,
                                                                  pageSize: .max)
                self.itemRevisions = itemRevisionList.revisionsData
            } catch {
                delegate?.vaultContentViewModelDidFailWithError(error: error)
            }
        }
    }

    private func decrypt(itemRevisions: [ItemRevision]) {
        guard let shareId = selectedVault?.shareId else { return }
        Task { @MainActor in
            do {
                let share = try await shareRepository.getShare(shareId: shareId)
                let shareKeys = try await shareKeysRepository.getShareKeys(shareId: shareId,
                                                                           page: 0,
                                                                           pageSize: .max)
                let verifyKeys = userData.user.keys.map { $0.publicKey }
                partialItemContents =
                try itemRevisions.map { try $0.getPartialContent(userData: userData,
                                                                 share: share,
                                                                 vaultKeys: shareKeys.vaultKeys,
                                                                 itemKeys: shareKeys.itemKeys,
                                                                 verifyKeys: verifyKeys) }
            } catch {
                delegate?.vaultContentViewModelDidFailWithError(error: error)
            }
        }
    }
}

// MARK: - Actions
extension VaultContentViewModel {
    func toggleSidebarAction() {
        delegate?.vaultContentViewModelWantsToToggleSidebar()
    }

    func searchAction() {
        delegate?.vaultContentViewModelWantsToSearch()
    }

    func createItemAction() {
        delegate?.vaultContentViewModelWantsToCreateNewItem()
    }

    func createVaultAction() {
        delegate?.vaultContentViewModelWantsToCreateNewVault()
    }
}
