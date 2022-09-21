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
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel

    var onTrashedItem: (() -> Void)?

    init(symmetricKey: SymmetricKey,
         userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.shareKeysRepository = shareKeysRepository
        self.aliasRepository = aliasRepository
        self.vaultContentViewModel = .init(vaultSelection: vaultSelection,
                                           itemRepository: itemRepository,
                                           symmetricKey: symmetricKey)
        self.myVaultsViewModel = MyVaultsViewModel(vaultSelection: vaultSelection)
        super.init()
        observeVaultContentViewModel()
        start()
    }

    private func observeVaultContentViewModel() {
        vaultContentViewModel.delegate = self
        vaultContentViewModel.onToggleSidebar = { [unowned self] in toggleSidebar() }
        vaultContentViewModel.onSearch = { [unowned self] in showSearchView() }
        vaultContentViewModel.onCreateItem = { [unowned self] in showCreateItemView() }
        vaultContentViewModel.onCreateVault = { [unowned self] in showCreateVaultView() }
        vaultContentViewModel.onShowItemDetail = { [unowned self] in showItemDetailView($0) }
        vaultContentViewModel.onTrashedItem = { [unowned self] in handleTrashedItem($0) }
    }

    private func start() {
        let loadVaultsViewModel = LoadVaultsViewModel(userData: userData,
                                                      vaultSelection: vaultSelection,
                                                      shareRepository: shareRepository,
                                                      shareKeysRepository: shareKeysRepository)
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
                    showGeneratePasswordView(delegate: nil)
                }
            }
        }
        let createItemView = CreateItemView(viewModel: createItemViewModel)
        let createItemViewController = UIHostingController(rootView: createItemView)
        if #available(iOS 15.0, *) {
            createItemViewController.sheetPresentationController?.detents = [.medium()]
        }
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
        if #available(iOS 15.0, *) {
            createVaultViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(createVaultViewController)
    }

    private func showCreateEditLoginView(mode: ItemMode) {
        let createEditLoginViewModel = CreateEditLoginViewModel(mode: mode,
                                                                itemRepository: itemRepository)
        createEditLoginViewModel.delegate = self
        createEditLoginViewModel.createEditItemDelegate = self
        createEditLoginViewModel.onGeneratePassword = { [unowned self] in showGeneratePasswordView(delegate: $0) }
        let createEditLoginView = CreateEditLoginView(viewModel: createEditLoginViewModel)
        presentViewFullScreen(createEditLoginView, modalTransitionStyle: mode.modalTransitionStyle)
    }

    private func showCreateEditAliasView(mode: ItemMode) {
        let createEditAliasViewModel = CreateEditAliasViewModel(mode: mode,
                                                                itemRepository: itemRepository,
                                                                aliasRepository: aliasRepository)
        createEditAliasViewModel.delegate = self
        createEditAliasViewModel.createEditItemDelegate = self
        let createEditAliasView = CreateEditAliasView(viewModel: createEditAliasViewModel)
        presentViewFullScreen(createEditAliasView, modalTransitionStyle: mode.modalTransitionStyle)
    }

    private func showCreateEditNoteView(mode: ItemMode) {
        let createEditNoteViewModel = CreateEditNoteViewModel(mode: mode,
                                                              itemRepository: itemRepository)
        createEditNoteViewModel.delegate = self
        createEditNoteViewModel.createEditItemDelegate = self
        let createEditNoteView = CreateEditNoteView(viewModel: createEditNoteViewModel)
        presentViewFullScreen(createEditNoteView, modalTransitionStyle: mode.modalTransitionStyle)
    }

    private func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?) {
        let viewModel = GeneratePasswordViewModel()
        viewModel.delegate = delegate
        let generatePasswordView = GeneratePasswordView(viewModel: viewModel)
        let generatePasswordViewController = UIHostingController(rootView: generatePasswordView)
        if #available(iOS 15, *) {
            generatePasswordViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(generatePasswordViewController)
    }

    private func showSearchView() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository)
        presentViewFullScreen(SearchView(viewModel: viewModel))
    }

    private func showItemDetailView(_ itemContent: ItemContent) {
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository)
            viewModel.delegate = self
            viewModel.itemDetailDelegate = self
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            pushView(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository)
            viewModel.delegate = self
            viewModel.itemDetailDelegate = self
            let noteDetailView = NoteDetailView(viewModel: viewModel)
            pushView(noteDetailView)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
            viewModel.delegate = self
            viewModel.itemDetailDelegate = self
            let aliasDetailView = AliasDetailView(viewModel: viewModel)
            pushView(aliasDetailView)
        }
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
            myVaultsViewModel.successMessage = message
            vaultContentViewModel.fetchItems()
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
        myVaultsViewModel.successMessage = message
        vaultContentViewModel.fetchItems()
        onTrashedItem?()
    }

    private func handleUpdatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            popToRoot()
            let message: String
            switch itemContentType {
            case .alias:
                message = "Alias updated"
            case .login:
                message = "Login updated"
            case .note:
                message = "Note updated"
            }
            myVaultsViewModel.successMessage = message
            vaultContentViewModel.fetchItems()
        }
    }

    func refreshItems() {
        vaultContentViewModel.fetchItems()
    }
}

// MARK: - BaseViewModelDelegate
extension MyVaultsCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() { showLoadingHud() }

    func viewModelStopsLoading() { hideLoadingHud() }

    func viewModelDidFailWithError(_ error: Error) { alertError(error) }
}

// MARK: - CreateEditItemViewModelDelegate
extension MyVaultsCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelDidCreateItem(_ type: ItemContentType) {
        handleCreatedItem(type)
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        handleUpdatedItem(type)
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

private extension ItemMode {
    var modalTransitionStyle: UIModalTransitionStyle {
        switch self {
        case .create:
            return .coverVertical
        case .edit:
            return .crossDissolve
        }
    }
}
