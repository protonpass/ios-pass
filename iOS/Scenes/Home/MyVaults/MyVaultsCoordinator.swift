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
import ProtonCore_Login
import SwiftUI

final class MyVaultsCoordinator: Coordinator {
    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let vaultContentViewModel: VaultContentViewModel
    private let shareRepository: ShareRepositoryProtocol
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel

    var onTrashedItem: (() -> Void)?

    init(userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol) {
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRevisionRepository = itemRevisionRepository
        self.shareKeysRepository = shareKeysRepository
        self.vaultContentViewModel = .init(userData: userData,
                                           vaultSelection: vaultSelection,
                                           shareRepository: shareRepository,
                                           itemRevisionRepository: itemRevisionRepository,
                                           shareKeysRepository: shareKeysRepository,
                                           publicKeyRepository: publicKeyRepository)
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

    func showCreateItemView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let mode = BaseCreateEditItemViewModel.Mode.create(shareId: shareId)
        let createItemViewModel = CreateItemViewModel()
        createItemViewModel.onSelectedOption = { [unowned self] option in
            dismissTopMostViewController(animated: true) { [unowned self] in
                switch option {
                case .login:
                    showCreateEditLoginView(mode: mode)
                case .alias:
                    showCreateAliasView()
                case .note:
                    showCreateEditNoteView(mode: mode)
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

    func showCreateVaultView() {
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

    func showCreateEditLoginView(mode: BaseCreateEditItemViewModel.Mode) {
        let createEditLoginViewModel = CreateEditLoginViewModel(mode: mode,
                                                                userData: userData,
                                                                shareRepository: shareRepository,
                                                                shareKeysRepository: shareKeysRepository,
                                                                itemRevisionRepository: itemRevisionRepository)
        createEditLoginViewModel.delegate = self
        createEditLoginViewModel.onGeneratePassword = { [unowned self] in showGeneratePasswordView(delegate: $0) }
        createEditLoginViewModel.onCreatedItem = { [unowned self] in handleCreatedItem($0) }
        createEditLoginViewModel.onUpdatedItem = { [unowned self] in handleUpdatedItem($0) }
        let createEditLoginView = CreateEditLoginView(viewModel: createEditLoginViewModel)
        presentViewFullScreen(createEditLoginView,
                              modalTransitionStyle: mode.modalTransitionStyle)
    }

    func showCreateAliasView() {
        let createAliasViewModel = CreateAliasViewModel()
        createAliasViewModel.delegate = self
        let createAliasView = CreateAliasView(viewModel: createAliasViewModel)
        presentViewFullScreen(createAliasView)
    }

    func showCreateEditNoteView(mode: BaseCreateEditItemViewModel.Mode) {
        let createEditNoteViewModel = CreateEditNoteViewModel(mode: mode,
                                                              userData: userData,
                                                              shareRepository: shareRepository,
                                                              shareKeysRepository: shareKeysRepository,
                                                              itemRevisionRepository: itemRevisionRepository)
        createEditNoteViewModel.delegate = self
        createEditNoteViewModel.onCreatedItem = { [unowned self] in handleCreatedItem($0) }
        createEditNoteViewModel.onUpdatedItem = { [unowned self] in handleUpdatedItem($0) }
        let createEditNoteView = CreateEditNoteView(viewModel: createEditNoteViewModel)
        presentViewFullScreen(createEditNoteView,
                              modalTransitionStyle: mode.modalTransitionStyle)
    }

    func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?) {
        let viewModel = GeneratePasswordViewModel()
        viewModel.delegate = delegate
        let generatePasswordView = GeneratePasswordView(viewModel: viewModel)
        let generatePasswordViewController = UIHostingController(rootView: generatePasswordView)
        if #available(iOS 15, *) {
            generatePasswordViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(generatePasswordViewController)
    }

    func showSearchView() {
        presentViewFullScreen(SearchView())
    }

    func showItemDetailView(_ itemContent: ItemContent) {
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRevisionRepository: itemRevisionRepository)
            viewModel.delegate = self
            viewModel.onEditItem = { [unowned self] in showEditItemView($0) }
            viewModel.onTrashedItem = { [unowned self] in handleTrashedItem($0) }
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            pushView(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRevisionRepository: itemRevisionRepository)
            viewModel.delegate = self
            viewModel.onEditItem = { [unowned self] in showEditItemView($0) }
            viewModel.onTrashedItem = { [unowned self] in handleTrashedItem($0) }
            let noteDetailView = NoteDetailView(viewModel: viewModel)
            pushView(noteDetailView)

        case .alias:
            break
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
        let mode = BaseCreateEditItemViewModel.Mode.edit(item)
        switch item.contentData.type {
        case .login:
            showCreateEditLoginView(mode: mode)
        case .note:
            showCreateEditNoteView(mode: mode)
        case .alias:
            break
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
}

// MARK: - BaseViewModelDelegate
extension MyVaultsCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() { showLoadingHud() }

    func viewModelStopsLoading() { hideLoadingHud() }

    func viewModelDidFailWithError(_ error: Error) { alertError(error) }
}

private extension BaseCreateEditItemViewModel.Mode {
    var modalTransitionStyle: UIModalTransitionStyle {
        switch self {
        case .create:
            return .coverVertical
        case .edit:
            return .crossDissolve
        }
    }
}
