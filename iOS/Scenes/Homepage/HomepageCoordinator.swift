//
// HomepageCoordinator.swift
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

// swiftlint:disable file_length
import Client
import Combine
import Core
import CoreData
import CryptoKit
import MBProgressHUD
import ProtonCore_Login
import ProtonCore_Services
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents
import UIKit

protocol HomepageCoordinatorDelegate: AnyObject {
    func homepageCoordinatorWantsToLogOut()
}

final class HomepageCoordinator: Coordinator, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Injected & self-initialized properties
    private let aliasRepository: AliasRepositoryProtocol
    private let clipboardManager: ClipboardManager
    private let credentialManager: CredentialManagerProtocol
    private let eventLoop: SyncEventLoop
    private let itemContextMenuHandler: ItemContextMenuHandler
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let manualLogIn: Bool
    private let logManager: LogManager
    private let preferences: Preferences
    private let searchEntryDatasource: LocalSearchEntryDatasourceProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let userData: UserData
    private let vaultsManager: VaultsManager

    // Lazily initialized properties
    private lazy var bannerManager: BannerManager = { .init(container: rootViewController) }()

    // References
    private var homepageViewModel: HomepageViewModel?
    private var currentItemDetailViewModel: BaseItemDetailViewModel?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var searchViewModel: SearchViewModel?
    private var deleteVaultAlertHandler: DeleteVaultAlertHandler?

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: HomepageCoordinatorDelegate?

    // swiftlint:disable:next function_body_length
    init(apiService: APIService,
         container: NSPersistentContainer,
         credentialManager: CredentialManagerProtocol,
         logManager: LogManager,
         manualLogIn: Bool,
         preferences: Preferences,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        let itemRepository = ItemRepository(userData: userData,
                                            symmetricKey: symmetricKey,
                                            container: container,
                                            apiService: apiService,
                                            logManager: logManager)
        let remoteAliasDatasource = RemoteAliasDatasource(apiService: apiService)
        let remoteSyncEventsDatasource = RemoteSyncEventsDatasource(apiService: apiService)
        let shareKeyRepository = ShareKeyRepository(container: container,
                                                    apiService: apiService,
                                                    logManager: logManager)
        let shareEventIDRepository = ShareEventIDRepository(container: container,
                                                            apiService: apiService,
                                                            logManager: logManager)
        let shareRepository = ShareRepository(userData: userData,
                                              container: container,
                                              apiService: apiService,
                                              logManager: logManager)

        self.aliasRepository = AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
        self.clipboardManager = .init(preferences: preferences)
        self.credentialManager = credentialManager
        self.eventLoop = .init(userId: userData.user.ID,
                               shareRepository: shareRepository,
                               shareEventIDRepository: shareEventIDRepository,
                               remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                               itemRepository: itemRepository,
                               shareKeyRepository: shareKeyRepository,
                               logManager: logManager)
        self.itemContextMenuHandler = .init(clipboardManager: clipboardManager,
                                            itemRepository: itemRepository,
                                            logManager: logManager)
        self.itemRepository = ItemRepository(userData: userData,
                                             symmetricKey: symmetricKey,
                                             container: container,
                                             apiService: apiService,
                                             logManager: logManager)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.logManager = logManager
        self.manualLogIn = manualLogIn
        self.preferences = preferences
        self.searchEntryDatasource = LocalSearchEntryDatasource(container: container)
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.vaultsManager = .init(itemRepository: itemRepository,
                                   manualLogIn: manualLogIn,
                                   logManager: logManager,
                                   shareRepository: shareRepository,
                                   symmetricKey: symmetricKey)
        super.init()
        self.finalizeInitialization()
        self.start()
        self.eventLoop.start()
    }
}

// MARK: - Private APIs
private extension HomepageCoordinator {
    /// Some properties are dependant on other propeties which are in turn not initialized
    /// before the Coordinator is fully initialized. This method is to resolve these dependencies.
    func finalizeInitialization() {
        eventLoop.delegate = self
        clipboardManager.bannerManager = bannerManager
        itemContextMenuHandler.delegate = self

        preferences.objectWillChange
            .sink { [unowned self] _ in
                self.rootViewController.overrideUserInterfaceStyle = self.preferences.theme.userInterfaceStyle
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [unowned self] _ in
                eventLoop.forceSync()
                Task {
                    do {
                        try await credentialManager.insertAllCredentials(from: itemRepository,
                                                                         symmetricKey: symmetricKey,
                                                                         forceRemoval: false)
                        logger.info("App goes back to foreground. Inserted all credentials.")
                    } catch {
                        logger.error(error)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        let homepageViewModel = HomepageViewModel(itemContextMenuHandler: itemContextMenuHandler,
                                                  itemRepository: itemRepository,
                                                  manualLogIn: manualLogIn,
                                                  logManager: logManager,
                                                  preferences: preferences,
                                                  shareRepository: shareRepository,
                                                  symmetricKey: symmetricKey,
                                                  syncEventLoop: eventLoop,
                                                  userData: userData,
                                                  vaultsManager: vaultsManager)
        homepageViewModel.delegate = self
        homepageViewModel.itemsTabViewModelDelegate = self
        let homepageView = HomepageView(viewModel: homepageViewModel)

        let placeholderView = ItemDetailPlaceholderView { [unowned self] in
            self.popTopViewController(animated: true)
        }

        start(with: homepageView, secondaryView: placeholderView)
        rootViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        self.homepageViewModel = homepageViewModel
    }

    func informAliasesLimit() {
        bannerManager.displayTopErrorMessage("You can not create more aliases.")
    }

    func presentItemDetailView(for itemContent: ItemContent) {
        let itemDetailView: any View
        let baseItemDetailViewModel: BaseItemDetailViewModel
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 logManager: logManager)
            viewModel.logInDetailViewModelDelegate = self
            baseItemDetailViewModel = viewModel
            itemDetailView = LogInDetailView(viewModel: viewModel)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository,
                                                logManager: logManager)
            baseItemDetailViewModel = viewModel
            itemDetailView = NoteDetailView(viewModel: viewModel)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 logManager: logManager)
            baseItemDetailViewModel = viewModel
            itemDetailView = AliasDetailView(viewModel: viewModel)
        }

        baseItemDetailViewModel.delegate = self
        currentItemDetailViewModel = baseItemDetailViewModel

        // Push on iPad, sheets on iPhone
        if UIDevice.current.isIpad {
            push(itemDetailView)
        } else {
            present(NavigationView { AnyView(itemDetailView) }.navigationViewStyle(.stack),
                    userInterfaceStyle: preferences.theme.userInterfaceStyle)
        }
    }

    func presentEditItemView(for itemContent: ItemContent) {
        let mode = ItemMode.edit(itemContent)
        switch itemContent.contentData.type {
        case .login:
            presentCreateEditLoginView(mode: mode)
        case .note:
            presentCreateEditNoteView(mode: mode)
        case .alias:
            presentCreateEditAliasView(mode: mode)
        }
    }

    func presentCreateItemView(shareId: String) {
        let view = ItemTypeListView { [unowned self] itemType in
            dismissTopMostViewController { [unowned self] in
                switch itemType {
                case .login:
                    let logInType = ItemCreationType.login(title: nil, url: nil, autofill: false)
                    self.presentCreateEditLoginView(mode: .create(shareId: shareId, type: logInType))
                case .alias:
                    self.presentCreateEditAliasView(mode: .create(shareId: shareId, type: .alias))
                case .note:
                    self.presentCreateEditNoteView(mode: .create(shareId: shareId, type: .other))
                case .password:
                    self.presentGeneratePasswordView(delegate: self, mode: .random)
                }
            }
        }
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                // 66 per row + nav bar height
                CGFloat(ItemType.allCases.count) * 66 + 72
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func presentCreateEditLoginView(mode: ItemMode) {
        let emailAddress = userData.addresses.first?.email ?? ""
        let viewModel = CreateEditLoginViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 preferences: preferences,
                                                 logManager: logManager,
                                                 emailAddress: emailAddress)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentCreateEditAliasView(mode: ItemMode) {
        let viewModel = CreateEditAliasViewModel(mode: mode,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 preferences: preferences,
                                                 logManager: logManager)
        viewModel.delegate = self
        viewModel.createEditAliasViewModelDelegate = self
        let view = CreateEditAliasView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentMailboxSelectionView(selection: MailboxSelection, mode: MailboxSelectionView.Mode) {
        let view = MailboxSelectionView(mailboxSelection: selection, mode: mode)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func presentCreateEditNoteView(mode: ItemMode) {
        let viewModel = CreateEditNoteViewModel(mode: mode,
                                                itemRepository: itemRepository,
                                                preferences: preferences,
                                                logManager: logManager)
        viewModel.delegate = self
        let view = CreateEditNoteView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?,
                                     mode: GeneratePasswordViewMode) {
        let viewModel = GeneratePasswordViewModel(mode: mode)
        viewModel.delegate = delegate
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            navigationController.sheetPresentationController?.detents = [customDetent]
        } else {
            navigationController.sheetPresentationController?.detents = [.medium()]
        }
        viewModel.onDismiss = { navigationController.dismiss(animated: true) }
        present(navigationController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func presentSortTypeList(selectedSortType: SortType,
                             delegate: SortTypeListViewModelDelegate) {
        let viewModel = SortTypeListViewModel(sortType: selectedSortType)
        viewModel.delegate = delegate
        let view = SortTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = CGFloat(44 * SortType.allCases.count + 60)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func presentCreateEditVaultView(mode: VaultMode) {
        let viewModel = CreateEditVaultViewModel(mode: mode,
                                                 shareRepository: shareRepository,
                                                 logManager: logManager)
        viewModel.delegate = self
        let view = CreateEditVaultView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func refreshHomepageAndSearchPage() {
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
    }
}

// MARK: - Public APIs
extension HomepageCoordinator {
    func onboardIfNecessary() {
        guard !preferences.onboarded else { return }
        let onboardingViewModel = OnboardingViewModel(credentialManager: credentialManager,
                                                      preferences: preferences,
                                                      bannerManager: bannerManager,
                                                      logManager: logManager)
        let onboardingView = OnboardingView(viewModel: onboardingViewModel)
        let onboardingViewController = UIHostingController(rootView: onboardingView)
        onboardingViewController.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        onboardingViewController.isModalInPresentation = true
        topMostViewController.present(onboardingViewController, animated: true)
    }
}

// MARK: - HomepageViewModelDelegate
extension HomepageCoordinator: HomepageViewModelDelegate {
    func homepageViewModelWantsToCreateNewItem(shareId: String) {
        presentCreateItemView(shareId: shareId)
    }

    func homepageViewModelWantsToLogOut() {
        eventLoop.stop()
        delegate?.homepageCoordinatorWantsToLogOut()
    }
}

// MARK: - ItemsTabViewModelDelegate
extension HomepageCoordinator: ItemsTabViewModelDelegate {
    func itemsTabViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemsTabViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func itemsTabViewModelWantsToCreateNewItem(shareId: String) {
        presentCreateItemView(shareId: shareId)
    }

    func itemsTabViewModelWantsToSearch(vaultSelection: VaultSelection) {
        let viewModel = SearchViewModel(itemContextMenuHandler: itemContextMenuHandler,
                                        itemRepository: itemRepository,
                                        logManager: logManager,
                                        searchEntryDatasource: searchEntryDatasource,
                                        symmetricKey: symmetricKey,
                                        vaultSelection: vaultSelection)
        viewModel.delegate = self
        searchViewModel = viewModel
        let view = SearchView(viewModel: viewModel)
        present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemsTabViewModelWantsToPresentVaultList(vaultsManager: VaultsManager) {
        let viewModel = EditableVaultListViewModel(vaultsManager: vaultsManager,
                                                   logManager: logManager)
        viewModel.delegate = self
        let view = EditableVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            // Num of vaults + all items + trash + create vault button
            let height = CGFloat(66 * vaultsManager.getVaultCount() + 66 + 66 + 100)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                     delegate: SortTypeListViewModelDelegate) {
        presentSortTypeList(selectedSortType: selectedSortType, delegate: delegate)
    }

    func itemsTabViewModelWantsViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent)
    }

    func itemsTabViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditItemViewModelDelegate
extension HomepageCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func createEditItemViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem, type: ItemContentType) {
        let message: String
        switch type {
        case .login:
            message = "Login created"
        case .alias:
            message = "Alias created"
        case .note:
            message = "Note created"
        }
        dismissTopMostViewController(animated: true) { [unowned self] in
            bannerManager.displayBottomInfoMessage(message)
        }
        vaultsManager.refresh()
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        let message: String
        switch type {
        case .login:
            message = "Login udpated"
        case .alias:
            message = "Alias udpated"
        case .note:
            message = "Note udpated"
        }
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
        currentItemDetailViewModel?.refresh()
        dismissTopMostViewController { [unowned self] in
            self.bannerManager.displayBottomInfoMessage(message)
        }
    }

    func createEditItemViewModelDidFail(_ error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditLoginViewModelDelegate
extension HomepageCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options,
                                                 creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        viewModel.delegate = self
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.sheetPresentationController?.detents = [.medium()]
        viewModel.onDismiss = { navigationController.dismiss(animated: true) }
        present(navigationController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        presentGeneratePasswordView(delegate: delegate, mode: .createLogin)
    }

    func createEditLoginViewModelWantsToOpenSettings() {
        UIApplication.shared.openAppSettings()
    }

    func createEditLoginViewModelCanNotCreateMoreAlias() {
        informAliasesLimit()
    }
}

// MARK: - CreateEditAliasViewModelDelegate
extension HomepageCoordinator: CreateEditAliasViewModelDelegate {
    func createEditAliasViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        presentMailboxSelectionView(selection: mailboxSelection, mode: .createEditAlias)
    }

    func createEditAliasViewModelCanNotCreateMoreAliases() {
        informAliasesLimit()
    }
}

// MARK: - CreateAliasLiteViewModelDelegate
extension HomepageCoordinator: CreateAliasLiteViewModelDelegate {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        presentMailboxSelectionView(selection: mailboxSelection, mode: .createAliasLite)
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension HomepageCoordinator: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.clipboardManager.copy(text: password, bannerMessage: "Password copied")
        }
    }
}

// MARK: - EditableVaultListViewModelDelegate
extension HomepageCoordinator: EditableVaultListViewModelDelegate {
    func editableVaultListViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func editableVaultListViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func editableVaultListViewModelWantsToCreateNewVault() {
        presentCreateEditVaultView(mode: .create)
    }

    func editableVaultListViewModelWantsToEdit(vault: Vault) {
        presentCreateEditVaultView(mode: .edit(vault))
    }

    func editableVaultListViewModelWantsToConfirmDelete(vault: Vault,
                                                        delegate: DeleteVaultAlertHandlerDelegate) {
        deleteVaultAlertHandler = .init(rootViewController: topMostViewController,
                                        vault: vault,
                                        delegate: delegate)
        deleteVaultAlertHandler?.showAlert()
    }

    func editableVaultListViewModelDidDelete(vault: Vault) {
        bannerManager.displayBottomInfoMessage("Vault \"\(vault.name)\" deleted")
        vaultsManager.refresh(deletedVault: vault)
    }

    func editableVaultListViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }

    func editableVaultListViewModelDidRestoreAllTrashedItems() {
        bannerManager.displayBottomSuccessMessage("All items restored")
        refreshHomepageAndSearchPage()
    }

    func editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems() {
        bannerManager.displayBottomInfoMessage("All items permanently deleted")
        refreshHomepageAndSearchPage()
    }
}

// MARK: - ItemDetailViewModelDelegate
extension HomepageCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemDetailViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func itemDetailViewModelWantsToGoBack() {
        // Dismiss differently because show differently
        // (push on iPad, sheets on iPhone)
        if UIDevice.current.isIpad {
            popTopViewController(animated: true)
        } else {
            dismissTopMostViewController()
        }
    }

    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }

    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager.copy(text: text, bannerMessage: bannerMessage)
    }

    func itemDetailViewModelWantsToShowFullScreen(_ text: String) {
        showFullScreen(text: text, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelWantsToOpen(urlString: String) {
        UrlOpener(preferences: preferences).open(urlString: urlString)
    }

    func itemDetailViewModelDidMove(oldItem: ItemIdentifiable, newItem: ItemIdentifiable, newVault: Vault) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage("Item moved to vault \"\(newVault.name)\"")
        }
        vaultsManager.refreshAfterMovingItem(oldItem: oldItem, newItem: newItem)
        searchViewModel?.refreshResults()
    }

    func itemDetailViewModelWantsToMove(item: ItemIdentifiable, delegate: MoveVaultListViewModelDelegate) {
        let allVaults = vaultsManager.getAllVaultContents()
        guard !allVaults.isEmpty,
              let currentVault = allVaults.first(where: { $0.vault.shareId == item.shareId }) else { return }
        let viewModel = MoveVaultListViewModel(allVaults: allVaults.map { .init(vaultContent: $0) },
                                               currentVault: .init(vaultContent: currentVault))
        viewModel.delegate = delegate
        let view = MoveVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = CGFloat(66 * allVaults.count + 44)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelDidMoveToTrash(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(trashedItem: item)
        searchViewModel?.refreshResults()
        dismissTopMostViewController(animated: true) { [unowned self] in
            let undoBlock: (PMBanner) -> Void = { [unowned self] banner in
                banner.dismiss()
                self.itemContextMenuHandler.restore(item)
            }
            self.bannerManager.displayBottomInfoMessage(item.type.trashMessage,
                                                        dismissButtonTitle: "Undo",
                                                        onDismiss: undoBlock)
        }
    }

    func itemDetailViewModelDidRestore(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(untrashedItem: item)
        searchViewModel?.refreshResults()
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
        }
    }

    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(permanentlyDeletedItem: item)
        searchViewModel?.refreshResults()
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomInfoMessage(item.type.deleteMessage)
        }
    }

    func itemDetailViewModelDidFail(_ error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - LogInDetailViewModelDelegate
extension HomepageCoordinator: LogInDetailViewModelDelegate {
    func logInDetailViewModelWantsToShowAliasDetail(_ itemContent: ItemContent) {
        presentItemDetailView(for: itemContent)
    }
}

// MARK: - ItemContextMenuHandlerDelegate
extension HomepageCoordinator: ItemContextMenuHandlerDelegate {
    func itemContextMenuHandlerWantsToShowSpinner() {
        showLoadingHud()
    }

    func itemContextMenuHandlerWantsToHideSpinner() {
        hideLoadingHud()
    }

    func itemContextMenuHandlerWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }

    func itemContextMenuHandlerDidTrash(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(trashedItem: item)
        searchViewModel?.refreshResults()
    }

    func itemContextMenuHandlerDidUntrash(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(untrashedItem: item)
        searchViewModel?.refreshResults()
    }

    func itemContextMenuHandlerDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        vaultsManager.refresh(permanentlyDeletedItem: item)
        searchViewModel?.refreshResults()
    }
}

// MARK: - SearchViewModelDelegate
extension HomepageCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent)
    }

    func searchViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                   delegate: SortTypeListViewModelDelegate) {
        presentSortTypeList(selectedSortType: selectedSortType, delegate: delegate)
    }

    func searchViewModelWantsDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - CreateEditVaultViewModelDelegate
extension HomepageCoordinator: CreateEditVaultViewModelDelegate {
    func createEditVaultViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func createEditVaultViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func createEditVaultViewModelDidCreateVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage("Vault created")
        }
        vaultsManager.refresh()
    }

    func createEditVaultViewModelDidEditVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomInfoMessage("Changes saved")
        }
        vaultsManager.refreshAfterVaultEdit()
    }

    func createEditVaultViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - SyncEventLoopDelegate
extension HomepageCoordinator: SyncEventLoopDelegate {
    func syncEventLoopDidStartLooping() {
        logger.info("Started looping")
    }

    func syncEventLoopDidStopLooping() {
        logger.info("Stopped looping")
    }

    func syncEventLoopDidBeginNewLoop() {
        logger.info("Began new sync loop")
    }

    #warning("Handle no connection reason")
    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason) {
        logger.info("Skipped sync loop \(reason)")
    }

    func syncEventLoopDidFinishLoop(hasNewEvents: Bool) {
        if hasNewEvents {
            logger.info("Has new events. Refreshing items")
            vaultsManager.refresh()
            currentItemDetailViewModel?.refresh()
            currentCreateEditItemViewModel?.refresh()
        } else {
            logger.info("Has no new events. Do nothing.")
        }
    }

    func syncEventLoopDidFailLoop(error: Error) {
        // Silently fail & not show error to users
        logger.error(error)
    }
}
