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

    private let vaultSelection: VaultSelection

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

    @Published private(set) var items = [Item]()
    @Published private(set) var partialItemContents = [PartialItemContent]()

    private let repository: RepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: VaultContentViewModelDelegate?

    init(vaultSelection: VaultSelection, repository: RepositoryProtocol) {
        self.vaultSelection = vaultSelection
        self.repository = repository

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)

        $items
            .sink { [unowned self] newItems in
                self.decrypt(items: newItems)
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
                let items = try await repository.getItems(forceUpdate: forceRefresh,
                                                          shareId: shareId,
                                                          page: 0,
                                                          pageSize: .max)
                self.items = items.revisionsData
            } catch {
                delegate?.vaultContentViewModelDidFailWithError(error: error)
            }
        }
    }

    private func decrypt(items: [Item]) {
        guard let shareId = selectedVault?.shareId else { return }
        Task { @MainActor in
            do {
                let shareKey = try await repository.getShareKey(forceUpdate: false,
                                                                shareId: shareId,
                                                                page: 0,
                                                                pageSize: .max)
                self.partialItemContents = try items.map { try $0.getPartialContent(shareKey: shareKey) }
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
