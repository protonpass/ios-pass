//
// MyVaultsCoordinator.swift
// Proton Pass - Created on 07/07/2022.
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
import ProtonCore_Login
import SwiftUI

final class MyVaultsCoordinator: Coordinator {
    private let symmetricKey: SymmetricKey
    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let vaultContentViewModel: VaultContentViewModel
    private let shareRepository: ShareRepositoryProtocol
    private let vaultItemKeysRepository: VaultItemKeysRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel

    private var currentItemDetailViewModel: BaseItemDetailViewModel?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?

    weak var itemCountDelegate: ItemCountDelegate? {
        didSet {
            vaultContentViewModel.itemCountDelegate = itemCountDelegate
        }
    }
    var onTrashedItem: (() -> Void)?

    init(symmetricKey: SymmetricKey,
         userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         vaultItemKeysRepository: VaultItemKeysRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.vaultItemKeysRepository = vaultItemKeysRepository
        self.aliasRepository = aliasRepository
        self.vaultContentViewModel = .init(vaultSelection: vaultSelection,
                                           itemRepository: itemRepository,
                                           symmetricKey: symmetricKey)
        self.myVaultsViewModel = MyVaultsViewModel(vaultSelection: vaultSelection)
        super.init()
        vaultContentViewModel.delegate = self
        vaultContentViewModel.vaultContentViewModelDelegate = self
        start()
    }

    private func start() {
        let loadVaultsViewModel = LoadVaultsViewModel(userData: userData,
                                                      vaultSelection: vaultSelection,
                                                      shareRepository: shareRepository,
                                                      vaultItemKeysRepository: vaultItemKeysRepository)
        loadVaultsViewModel.onToggleSidebar = { [unowned self] in toggleSidebar() }
        self.start(with: MyVaultsView(myVaultsViewModel: myVaultsViewModel,
                                      loadVaultsViewModel: loadVaultsViewModel,
                                      vaultContentViewModel: vaultContentViewModel))
    }

    private func showCreateItemView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let createItemViewModel = CreateItemViewModel()
        createItemViewModel.onSelectedOption = { [unowned self] option in
            dismissTopMostViewController(animated: true) { [unowned self] in
                switch option {
                case .login:
                    showCreateEditLoginView(mode: .create(shareId: shareId, alias: false))
                case .alias:
                    showCreateEditAliasView(mode: .create(shareId: shareId, alias: true))
                case .note:
                    showCreateEditNoteView(mode: .create(shareId: shareId, alias: false))
                case .password:
                    showGeneratePasswordView(delegate: self, mode: .random)
                }
            }
        }
        let createItemView = CreateItemView(viewModel: createItemViewModel)
        let createItemViewController = UIHostingController(rootView: createItemView)
        createItemViewController.sheetPresentationController?.detents = [.medium(), .large()]
        presentViewController(createItemViewController)
    }

    private func showCreateVaultView() {
        let createVaultViewModel =
        CreateVaultViewModel(userData: userData,
                             shareRepository: shareRepository)
        createVaultViewModel.delegate = self
        createVaultViewModel.onCreatedShare = { [unowned self] _ in
            // Set vaults to empty to trigger refresh
            self.vaultSelection.update(vaults: [])
            self.dismissTopMostViewController()
        }
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        let createVaultViewController = UIHostingController(rootView: createVaultView)
        createVaultViewController.sheetPresentationController?.detents = [.medium()]
        presentViewController(createVaultViewController)
    }

    private func showCreateEditLoginView(mode: ItemMode) {
        let viewModel = CreateEditLoginViewModel(mode: mode,
                                                 itemRepository: itemRepository)
        viewModel.delegate = self
        viewModel.createEditItemDelegate = self
        viewModel.onGeneratePassword = { [unowned self] in
            showGeneratePasswordView(delegate: $0, mode: .createLogin)
        }
        let view = CreateEditLoginView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditAliasView(mode: ItemMode) {
        let viewModel = CreateEditAliasViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
        viewModel.delegate = self
        viewModel.createEditItemDelegate = self
        let view = CreateEditAliasView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditNoteView(mode: ItemMode) {
        let viewModel = CreateEditNoteViewModel(mode: mode,
                                                itemRepository: itemRepository)
        viewModel.delegate = self
        viewModel.createEditItemDelegate = self
        let view = CreateEditNoteView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    private func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?,
                                          mode: GeneratePasswordViewMode) {
        let viewModel = GeneratePasswordViewModel(mode: mode)
        viewModel.delegate = delegate
        let generatePasswordView = GeneratePasswordView(viewModel: viewModel)
        let generatePasswordViewController = UIHostingController(rootView: generatePasswordView)
        generatePasswordViewController.sheetPresentationController?.detents = [.medium()]
        presentViewController(generatePasswordViewController)
    }

    private func showSearchView() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository)
        presentViewFullScreen(SearchView(viewModel: viewModel))
    }

    private func showItemDetailView(_ itemContent: ItemContent) {
        let baseItemDetailViewModel: BaseItemDetailViewModel
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            pushView(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let noteDetailView = NoteDetailView(viewModel: viewModel)
            pushView(noteDetailView)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
            baseItemDetailViewModel = viewModel
            let aliasDetailView = AliasDetailView(viewModel: viewModel)
            pushView(aliasDetailView)
        }

        baseItemDetailViewModel.delegate = self
        baseItemDetailViewModel.itemDetailDelegate = self
        currentItemDetailViewModel = baseItemDetailViewModel
    }

    private func handleCreatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            let message: String
            switch itemContentType {
            case .alias:
                message = "Alias created"
            case .login:
                message = "Login created"
            case .note:
                message = "Note created"
            }
            vaultContentViewModel.successMessage = message
            vaultContentViewModel.fetchItems(forceRefresh: false)
        }
    }

    private func showEditItemView(_ item: ItemContent) {
        let mode = ItemMode.edit(item)
        switch item.contentData.type {
        case .login:
            showCreateEditLoginView(mode: mode)
        case .note:
            showCreateEditNoteView(mode: mode)
        case .alias:
            showCreateEditAliasView(mode: .edit(item))
        }
    }

    private func handleTrashedItem(_ itemContentType: ItemContentType) {
        let message: String
        switch itemContentType {
        case .alias:
            message = "Alias deleted"
        case .login:
            message = "Login deleted"
        case .note:
            message = "Note deleted"
        }
        vaultContentViewModel.informativeMessage = message
        vaultContentViewModel.fetchItems(forceRefresh: false)
        onTrashedItem?()
    }

    private func handleUpdatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            vaultContentViewModel.successMessage = "Changes saved"
            vaultContentViewModel.fetchItems(forceRefresh: false)
        }
    }

    func refreshItems() {
        vaultContentViewModel.fetchItems(forceRefresh: false)
        currentItemDetailViewModel?.refresh()
        currentCreateEditItemViewModel?.refresh()
    }

    func updateFilterOption(_ filterOption: ItemTypeFilterOption) {
        vaultContentViewModel.filterOption = filterOption
    }
}

// MARK: - BaseViewModelDelegate
extension MyVaultsCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() { showLoadingHud() }

    func viewModelStopsLoading() { hideLoadingHud() }

    func viewModelDidFailWithError(_ error: Error) { alertError(error) }
}

// MARK: - VaultContentViewModelDelegate
extension MyVaultsCoordinator: VaultContentViewModelDelegate {
    func vaultContentViewModelWantsToToggleSidebar() {
        toggleSidebar()
    }

    func vaultContentViewModelWantsToSearch() {
        showSearchView()
    }

    func vaultContentViewModelWantsToCreateItem() {
        showCreateItemView()
    }

    func vaultContentViewModelWantsToCreateVault() {
        showCreateVaultView()
    }

    func vaultContentViewModelWantsToShowItemDetail(_ item: ItemContent) {
        showItemDetailView(item)
    }

    func vaultContentViewModelWantsToEditItem(_ item: ItemContent) {
        showEditItemView(item)
    }

    func vaultContentViewModelDidTrashItem(_ type: ItemContentType) {
        handleTrashedItem(type)
    }
}

// MARK: - CreateEditItemViewModelDelegate
extension MyVaultsCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelDidCreateItem(_ type: ItemContentType) {
        handleCreatedItem(type)
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        handleUpdatedItem(type)
    }

    func createEditItemViewModelDidTrashItem(_ type: ItemContentType) {
        popToRoot()
        handleTrashedItem(type)
    }
}

// MARK: - ItemDetailViewModelDelegate
extension MyVaultsCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        showEditItemView(itemContent)
    }

    func itemDetailViewModelDidTrashItem(_ type: ItemContentType) {
        handleTrashedItem(type)
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension MyVaultsCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        UIPasteboard.general.string = password
        vaultContentViewModel.informativeMessage = "Password copied"
    }
}
