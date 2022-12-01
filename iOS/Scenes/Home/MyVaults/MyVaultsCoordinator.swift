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
import UIComponents

protocol MyVaultsCoordinatorDelegate: AnyObject {
    func myVaultsCoordinatorWantsToRefreshTrash()
}

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

    weak var delegate: MyVaultsCoordinatorDelegate?

    weak var bannerManager: BannerManager?

    init(symmetricKey: SymmetricKey,
         userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         vaultItemKeysRepository: VaultItemKeysRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol,
         syncEventLoop: SyncEventLoop) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.vaultItemKeysRepository = vaultItemKeysRepository
        self.aliasRepository = aliasRepository
        self.vaultContentViewModel = .init(vaultSelection: vaultSelection,
                                           itemRepository: itemRepository,
                                           symmetricKey: symmetricKey,
                                           syncEventLoop: syncEventLoop)
        self.myVaultsViewModel = MyVaultsViewModel(vaultSelection: vaultSelection)
        super.init()
        vaultContentViewModel.delegate = self
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
                    showCreateEditLoginView(mode: .create(shareId: shareId,
                                                          type: .other))
                case .alias:
                    showCreateEditAliasView(mode: .create(shareId: shareId,
                                                          type: .alias(delegate: nil, title: "")))
                case .note:
                    showCreateEditNoteView(mode: .create(shareId: shareId,
                                                         type: .other))
                case .password:
                    showGeneratePasswordView(delegate: self, mode: .random)
                }
            }
        }
        let createItemView = CreateItemView(viewModel: createItemViewModel)
        let createItemViewController = UIHostingController(rootView: createItemView)
        createItemViewController.sheetPresentationController?.detents = [.medium(), .large()]
        presentViewController(createItemViewController, dismissible: true)
    }

    private func showCreateVaultView() {
        let createVaultViewModel =
        CreateVaultViewModel(userData: userData,
                             shareRepository: shareRepository)
        createVaultViewModel.delegate = self
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        let createVaultViewController = UIHostingController(rootView: createVaultView)
        createVaultViewController.sheetPresentationController?.detents = [.medium()]
        presentViewController(createVaultViewController)
    }

    private func showCreateEditLoginView(mode: ItemMode) {
        let viewModel = CreateEditLoginViewModel(mode: mode,
                                                 itemRepository: itemRepository)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditAliasView(mode: ItemMode) {
        let viewModel = CreateEditAliasViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
        viewModel.delegate = self
        viewModel.createEditAliasViewModelDelegate = self
        if case let .create(_, type) = mode,
           case let .alias(aliasCreationDelegate, title) = type {
            viewModel.aliasCreationDelegate = aliasCreationDelegate
            viewModel.title = title
        }
        let view = CreateEditAliasView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditNoteView(mode: ItemMode) {
        let viewModel = CreateEditNoteViewModel(mode: mode,
                                                itemRepository: itemRepository)
        viewModel.delegate = self
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
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            generatePasswordViewController.sheetPresentationController?.detents = [customDetent]
        } else {
            generatePasswordViewController.sheetPresentationController?.detents = [.medium()]
        }
        presentViewController(generatePasswordViewController, dismissible: true)
    }

    private func showSearchView() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository)
        viewModel.delegate = self
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
        currentItemDetailViewModel = baseItemDetailViewModel
    }

    private func showLargeView(text: String) {
        presentView(LargeView(text: text), dismissible: true)
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
            bannerManager?.displayBottomSuccessMessage(message)
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
            showCreateEditAliasView(mode: mode)
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
        bannerManager?.displayBottomInfoMessage(message)
        vaultContentViewModel.fetchItems(forceRefresh: false)
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
    }

    private func handleUpdatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            currentItemDetailViewModel?.refresh()
            bannerManager?.displayBottomSuccessMessage("Changes saved")
            vaultContentViewModel.fetchItems(forceRefresh: false)
        }
    }

    func refreshItems() {
        vaultContentViewModel.fetchItems(forceRefresh: false)
        if let aliasDetailViewModel = currentItemDetailViewModel as? AliasDetailViewModel {
            aliasDetailViewModel.refresh()
        } else {
            currentItemDetailViewModel?.refresh()
        }
        currentCreateEditItemViewModel?.refresh()
    }

    func updateFilterOption(_ filterOption: ItemTypeFilterOption) {
        vaultContentViewModel.filterOption = filterOption
    }
}

// MARK: - CreateVaultViewModelDelegate
extension MyVaultsCoordinator: CreateVaultViewModelDelegate {
    func createVaultViewModelDidCreateShare(_ share: Share) {
        // Set vaults to empty to trigger refresh
        self.vaultSelection.update(vaults: [])
        self.dismissTopMostViewController()
    }

    func createVaultViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - VaultContentViewModelDelegate
extension MyVaultsCoordinator: VaultContentViewModelDelegate {
    func vaultContentViewModelWantsToToggleSidebar() {
        toggleSidebar()
    }

    func vaultContentViewModelWantsToShowLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToShowLoadingHud()
    }

    func vaultContentViewModelWantsToHideLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToHideLoadingHud()
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

    func vaultContentViewModelWantsToDisplayInformativeMessage(_ message: String) {
        bannerManager?.displayBottomInfoMessage(message)
    }

    func vaultContentViewModelDidTrashItem(_ type: ItemContentType) {
        handleTrashedItem(type)
    }

    func vaultContentViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditItemViewModelDelegate
extension MyVaultsCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToShowLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToShowLoadingHud()
    }

    func createEditItemViewModelWantsToHideLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToHideLoadingHud()
    }

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

    func createEditItemViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditAliasViewModelDelegate
extension MyVaultsCoordinator: CreateEditAliasViewModelDelegate {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        let view = MailboxesView(mailboxSelection: mailboxSelection)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        presentViewController(viewController, dismissible: true)
    }
}

// MARK: - CreateEditLoginViewModelDelegate
extension MyVaultsCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(_ delegate: AliasCreationDelegate,
                                                      title: String) {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        showCreateEditAliasView(mode: .create(shareId: shareId,
                                              type: .alias(delegate: delegate,
                                                           title: title)))
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate, mode: .createLogin)
    }

    func createEditLoginViewModelDidRemoveAlias() {
        bannerManager?.displayBottomInfoMessage("Alias deleted")
        vaultContentViewModel.fetchItems(forceRefresh: false)
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
    }
}

// MARK: - ItemDetailViewModelDelegate
extension MyVaultsCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        showEditItemView(itemContent)
    }

    func itemDetailViewModelWantsToRestore(_ item: ItemListUiModel) {
        print("\(#function) not applicable")
    }

    func itemDetailViewModelDidTrashItem(_ type: ItemContentType) {
        handleTrashedItem(type)
    }

    func itemDetailViewModelWantsToDisplayInformativeMessage(_ message: String) {
        bannerManager?.displayBottomInfoMessage(message)
    }

    func itemDetailViewModelWantsToShowLarge(_ text: String) {
        showLargeView(text: text)
    }

    func itemDetailViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension MyVaultsCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController { [unowned self] in
            UIPasteboard.general.string = password
            self.bannerManager?.displayBottomInfoMessage("Password copied")
        }
    }
}

// MARK: - SearchViewModelDelegate
extension MyVaultsCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToShowLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToShowLoadingHud()
    }

    func searchViewModelWantsToHideLoadingHud() {
        coordinatorDelegate?.coordinatorWantsToHideLoadingHud()
    }

    func searchViewModelWantsToShowItemDetail(_ item: Client.ItemContent) {}

    func searchViewModelWantsToEditItem(_ item: Client.ItemContent) {}

    func searchViewModelWantsToDisplayInformativeMessage(_ message: String) {
        bannerManager?.displayBottomInfoMessage(message)
    }

    func searchViewModelDidTrashItem(_ type: Client.ItemContentType) {}

    func searchViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error.messageForTheUser)
    }
}
