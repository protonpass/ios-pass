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
    private let credentialManager: CredentialManagerProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let myVaultsViewModel: MyVaultsViewModel

    private var currentItemDetailViewModel: BaseItemDetailViewModel?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var searchViewModel: SearchViewModel?

    weak var itemCountDelegate: ItemCountDelegate? {
        didSet {
            vaultContentViewModel.itemCountDelegate = itemCountDelegate
        }
    }

    weak var delegate: MyVaultsCoordinatorDelegate?
    weak var bannerManager: BannerManager?
    weak var clipboardManager: ClipboardManager?
    weak var urlOpener: UrlOpener?

    init(symmetricKey: SymmetricKey,
         userData: UserData,
         vaultSelection: VaultSelection,
         shareRepository: ShareRepositoryProtocol,
         vaultItemKeysRepository: VaultItemKeysRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         publicKeyRepository: PublicKeyRepositoryProtocol,
         credentialManager: CredentialManagerProtocol,
         syncEventLoop: SyncEventLoop,
         preferences: Preferences) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultSelection = vaultSelection
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.credentialManager = credentialManager
        self.vaultItemKeysRepository = vaultItemKeysRepository
        self.aliasRepository = aliasRepository
        self.vaultContentViewModel = .init(vaultSelection: vaultSelection,
                                           itemRepository: itemRepository,
                                           credentialManager: credentialManager,
                                           symmetricKey: symmetricKey,
                                           syncEventLoop: syncEventLoop,
                                           preferences: preferences)
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
                                      vaultContentViewModel: vaultContentViewModel),
                   secondaryView: ItemDetailPlaceholderView { self.popTopViewController(animated: true) })
    }

    private func showCreateItemView() {
        guard let shareId = vaultSelection.selectedVault?.shareId else { return }
        let createItemViewModel = CreateItemViewModel()
        createItemViewModel.onSelectedOption = { [unowned self] option in
            dismissTopMostViewController(animated: true) { [unowned self] in
                switch option {
                case .login:
                    showCreateEditLoginView(mode: .create(shareId: shareId,
                                                          type: .login(title: nil,
                                                                       url: nil,
                                                                       autofill: false)))
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
        present(createItemViewController)
    }

    private func showCreateVaultView() {
        let createVaultViewModel =
        CreateVaultViewModel(userData: userData,
                             shareRepository: shareRepository)
        createVaultViewModel.delegate = self
        let createVaultView = CreateVaultView(viewModel: createVaultViewModel)
        let createVaultViewController = UIHostingController(rootView: createVaultView)
        createVaultViewController.sheetPresentationController?.detents = [.medium()]
        present(createVaultViewController)
    }

    private func showCreateEditLoginView(mode: ItemMode) {
        let viewModel = CreateEditLoginViewModel(mode: mode,
                                                 itemRepository: itemRepository)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        present(view, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditAliasView(mode: ItemMode) {
        let viewModel = CreateEditAliasViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
        viewModel.delegate = self
        viewModel.createEditAliasViewModelDelegate = self
        let view = CreateEditAliasView(viewModel: viewModel)
        present(view, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    private func showCreateEditNoteView(mode: ItemMode) {
        let viewModel = CreateEditNoteViewModel(mode: mode,
                                                itemRepository: itemRepository)
        viewModel.delegate = self
        let view = CreateEditNoteView(viewModel: viewModel)
        present(view, dismissible: false)
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
        present(generatePasswordViewController)
    }

    private func showSearchView() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository)
        viewModel.delegate = self
        searchViewModel = viewModel
        let viewController = UIHostingController(rootView: SearchView(viewModel: viewModel))
        let navigationController = UINavigationController(rootViewController: viewController)
        if UIDevice.current.isIpad {
            navigationController.modalPresentationStyle = .formSheet
        } else {
            navigationController.modalPresentationStyle = .fullScreen
            navigationController.modalTransitionStyle = .coverVertical
        }
        present(navigationController, dismissible: UIDevice.current.isIpad)
    }

    private func showItemDetailView(_ itemContent: ItemContent) {
        let baseItemDetailViewModel: BaseItemDetailViewModel
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            push(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let noteDetailView = NoteDetailView(viewModel: viewModel)
            push(noteDetailView)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
            baseItemDetailViewModel = viewModel
            let aliasDetailView = AliasDetailView(viewModel: viewModel)
            push(aliasDetailView)
        }

        baseItemDetailViewModel.delegate = self
        currentItemDetailViewModel = baseItemDetailViewModel
    }

    private func handleCreatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager?.displayBottomSuccessMessage(itemContentType.creationMessage)
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

    private func handleTrashedItem(_ item: ItemIdentifiable, type: ItemContentType) {
        let message: String
        switch type {
        case .alias:
            message = "Alias deleted"
        case .login:
            message = "Login deleted"
        case .note:
            message = "Note deleted"
        }

        if isAtRootViewController() {
            bannerManager?.displayBottomInfoMessage(message)
        } else {
            dismissTopMostViewController(animated: true) { [unowned self] in
                var placeholderViewController: UIViewController?
                if UIDevice.current.isIpad,
                   let currentItemDetailViewModel,
                   currentItemDetailViewModel.itemContent.shareId == item.shareId,
                   currentItemDetailViewModel.itemContent.itemId == item.itemId {
                    let placeholderView = ItemDetailPlaceholderView { self.popTopViewController(animated: true) }
                    placeholderViewController = UIHostingController(rootView: placeholderView)
                }
                self.popToRoot(animated: true, secondaryViewController: placeholderViewController)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [unowned self] in
                    self.bannerManager?.displayBottomInfoMessage(message)
                }
            }
        }

        vaultContentViewModel.fetchItems(forceRefresh: false)
        delegate?.myVaultsCoordinatorWantsToRefreshTrash()
        Task { await searchViewModel?.refreshResults() }
    }

    private func handleUpdatedItem(_ itemContentType: ItemContentType) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            currentItemDetailViewModel?.refresh()
            bannerManager?.displayBottomSuccessMessage("Changes saved")
            vaultContentViewModel.fetchItems(forceRefresh: false)
            Task { await searchViewModel?.refreshResults() }
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
        self.dismissTopMostViewController(animated: true, completion: nil)
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

    func vaultContentViewModelWantsToEnableAutoFill() {
        let view = TurnOnAutoFillView(credentialManager: credentialManager)
        let viewController = UIHostingController(rootView: view)
        if !UIDevice.current.isIpad {
            viewController.modalPresentationStyle = .fullScreen
        }
        present(viewController, dismissible: false)
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

    func vaultContentViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func vaultContentViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        handleTrashedItem(item, type: type)
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

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType) {
        handleCreatedItem(type)
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        handleUpdatedItem(type)
    }

    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        handleTrashedItem(item, type: type)
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
        present(viewController, animated: true, dismissible: true)
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

    func createEditLoginViewModelDidReceiveAliasCreationInfo() {
        dismissTopMostViewController(animated: true, completion: nil)
    }
}

// MARK: - ItemDetailViewModelDelegate
extension MyVaultsCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToGoBack() {
        popTopViewController(animated: true)
    }

    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        showEditItemView(itemContent)
    }

    func itemDetailViewModelWantsToRestore(_ item: ItemListUiModel) {
        print("\(#function) not applicable")
    }

    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func itemDetailViewModelWantsToShowFullScreen(_ text: String) {
        showFullScreen(text: text, userInterfaceStyle: rootViewController.parent?.overrideUserInterfaceStyle)
    }

    func itemDetailViewModelWantsToOpen(urlString: String) {
        urlOpener?.open(urlString: urlString)
    }

    func itemDetailViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension MyVaultsCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            clipboardManager?.copy(text: password, bannerMessage: "Password copied")
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

    func searchViewModelWantsToDismiss() {
        dismissTopMostViewController(animated: true, completion: nil)
    }

    func searchViewModelWantsToShowItemDetail(_ item: Client.ItemContent) {
        showItemDetailView(item)
    }

    func searchViewModelWantsToEditItem(_ item: Client.ItemContent) {
        showEditItemView(item)
    }

    func searchViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager?.copy(text: text, bannerMessage: bannerMessage)
    }

    func searchViewModelDidTrashItem(_ item: ItemIdentifiable, type: Client.ItemContentType) {
        handleTrashedItem(item, type: type)
    }

    func searchViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error.messageForTheUser)
    }
}
