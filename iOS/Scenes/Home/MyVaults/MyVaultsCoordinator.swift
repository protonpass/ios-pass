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

protocol MyVaultsCoordinatorDelegate: AnyObject {
    func myVautsCoordinatorWantsToShowSidebar()
    func myVautsCoordinatorWantsToShowLoadingHud()
    func myVautsCoordinatorWantsToHideLoadingHud()
    func myVautsCoordinatorWantsToAlertError(_ error: Error)
}

final class MyVaultsCoordinator: Coordinator {
    weak var delegate: MyVaultsCoordinatorDelegate?

    private let userData: UserData
    private let vaultSelection: VaultSelection
    private let vaultContentViewModel: VaultContentViewModel
    private let shareRepository: ShareRepositoryProtocol
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel

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

        let loadVaultsViewModel = LoadVaultsViewModel(userData: userData,
                                                      vaultSelection: vaultSelection,
                                                      shareRepository: shareRepository,
                                                      shareKeysRepository: shareKeysRepository)

        self.vaultContentViewModel.delegate = self
        loadVaultsViewModel.onToggleSidebar = { [unowned self] in showSidebar() }
        self.start(with: MyVaultsView(myVaultsViewModel: myVaultsViewModel,
                                      loadVaultsViewModel: loadVaultsViewModel,
                                      vaultContentViewModel: vaultContentViewModel))
    }

    func showSidebar() {
        delegate?.myVautsCoordinatorWantsToShowSidebar()
    }

    func showCreateItemView() {
        let createItemViewModel = CreateItemViewModel()
        createItemViewModel.onSelectedOption = { [unowned self] option in
            dismissTopMostViewController(animated: true) { [unowned self] in
                switch option {
                case .login:
                    showCreateLoginView()
                case .alias:
                    showCreateAliasView()
                case .note:
                    showCreateNoteView()
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

    func showCreateLoginView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let createLoginViewModel = CreateLoginViewModel(shareId: shareId,
                                                        userData: userData,
                                                        shareRepository: shareRepository,
                                                        shareKeysRepository: shareKeysRepository,
                                                        itemRevisionRepository: itemRevisionRepository)
        createLoginViewModel.delegate = self
        createLoginViewModel.createLoginDelegate = self
        createLoginViewModel.onCreatedItem = { [unowned self] in handleCreatedItem($0) }
        let createLoginView = CreateLoginView(viewModel: createLoginViewModel)
        presentViewFullScreen(createLoginView)
    }

    func showCreateAliasView() {
        let createAliasViewModel = CreateAliasViewModel()
        createAliasViewModel.delegate = self
        let createAliasView = CreateAliasView(viewModel: createAliasViewModel)
        presentViewFullScreen(createAliasView)
    }

    func showCreateNoteView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let createNoteViewModel = CreateNoteViewModel(shareId: shareId,
                                                      userData: userData,
                                                      shareRepository: shareRepository,
                                                      shareKeysRepository: shareKeysRepository,
                                                      itemRevisionRepository: itemRevisionRepository)
        createNoteViewModel.delegate = self
        createNoteViewModel.onCreatedItem = { [unowned self] in handleCreatedItem($0) }
        let createNoteView = CreateNoteView(viewModel: createNoteViewModel)
        presentViewFullScreen(createNoteView)
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

    func showItemDetailView(itemContent: ItemContent) {
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRevisionRepository: itemRevisionRepository)
            viewModel.delegate = self
            viewModel.onTrashedItem = { [unowned self] in handleTrashedItem($0) }
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            pushView(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRevisionRepository: itemRevisionRepository)
            viewModel.delegate = self
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
    }
}

// MARK: - VaultContentViewModelDelegate
extension MyVaultsCoordinator: VaultContentViewModelDelegate {
    func vaultContentViewModelWantsToToggleSidebar() {
        showSidebar()
    }

    func vaultContentViewModelWantsToSearch() {
        showSearchView()
    }

    func vaultContentViewModelWantsToCreateNewItem() {
        showCreateItemView()
    }

    func vaultContentViewModelWantsToCreateNewVault() {
        showCreateVaultView()
    }

    func vaultContentViewModelWantsToShowItemDetail(itemContent: ItemContent) {
        showItemDetailView(itemContent: itemContent)
    }

    func vaultContentViewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func vaultContentViewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func vaultContentViewModelDidFinishTrashing(_ itemContentType: ItemContentType) {
        handleTrashedItem(itemContentType)
    }

    func vaultContentViewModelDidFailWithError(error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}

// MARK: - CreateLoginViewModelDelegate
extension MyVaultsCoordinator: CreateLoginViewModelDelegate {
    func createLoginViewModelWantsToGeneratePassword(delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate)
    }
}

// MARK: - BaseViewModelDelegate
extension MyVaultsCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() {
        delegate?.myVautsCoordinatorWantsToShowLoadingHud()
    }

    func viewModelStopsLoading() {
        delegate?.myVautsCoordinatorWantsToHideLoadingHud()
    }

    func viewModelDidFailWithError(_ error: Error) {
        delegate?.myVautsCoordinatorWantsToAlertError(error)
    }
}
