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

import Client
import Combine
import Core
import CoreData
import CryptoKit
import MBProgressHUD
import ProtonCore_Login
import ProtonCore_Services
import SwiftUI
import UIComponents
import UIKit

final class HomepageCoordinator: Coordinator, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Injected & self-initialized properties
    private let aliasRepository: AliasRepositoryProtocol
    private let clipboardManager: ClipboardManager
    private let credentialManager: CredentialManagerProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let logManager: LogManager
    private let preferences: Preferences
    private let shareRepository: ShareRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let userData: UserData

    // Lazily initialized properties
    private lazy var bannerManager: BannerManager = { .init(container: rootViewController) }()

    // References
    private weak var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private weak var searchViewModel: SearchViewModel?

    private var cancellables = Set<AnyCancellable>()

    init(apiService: APIService,
         container: NSPersistentContainer,
         credentialManager: CredentialManagerProtocol,
         logManager: LogManager,
         preferences: Preferences,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        let authCredential = userData.credential
        let remoteAliasDatasource = RemoteAliasDatasource(authCredential: authCredential,
                                                          apiService: apiService)
        self.aliasRepository =
        AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
        self.clipboardManager = .init(preferences: preferences)
        self.credentialManager = credentialManager
        self.itemRepository = ItemRepository(userData: userData,
                                             symmetricKey: symmetricKey,
                                             container: container,
                                             apiService: apiService,
                                             logManager: logManager)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.logManager = logManager
        self.preferences = preferences
        self.shareRepository = ShareRepository(userData: userData,
                                               container: container,
                                               authCredential: authCredential,
                                               apiService: apiService,
                                               logManager: logManager)
        self.symmetricKey = symmetricKey
        self.userData = userData
        super.init()
        self.finalizeInitialization()
        self.start()
    }
}

// MARK: - Private APIs
private extension HomepageCoordinator {
    /// Some properties are dependant on other propeties which are in turn not initialized
    /// before the Coordinator is fully initialized. This method is to resolve these dependencies.
    func finalizeInitialization() {
        clipboardManager.bannerManager = bannerManager

        preferences.objectWillChange
            .sink { _ in
                self.rootViewController.overrideUserInterfaceStyle = self.preferences.theme.userInterfaceStyle
            }
            .store(in: &cancellables)
    }

    func start() {
        let homepageViewModel = HomepageViewModel(itemRepository: itemRepository,
                                                  logManager: logManager,
                                                  preferences: preferences,
                                                  shareRepository: shareRepository,
                                                  symmetricKey: symmetricKey,
                                                  userData: userData)
        homepageViewModel.delegate = self
        let homepageView = HomepageView(viewModel: homepageViewModel)

        let placeholderView = ItemDetailPlaceholderView {
            self.popTopViewController(animated: true)
        }

        start(with: homepageView, secondaryView: placeholderView)
        rootViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
    }

    func informAliasesLimit() {
        bannerManager.displayTopErrorMessage("You can not create more aliases.")
    }

    func presentCreateItemView() {
        let shareId = "39hry1jlHiPzhXRXrWjfS6t3fqA14QbYfrbF30l2PYYWOhVpyJ33nhujM4z4SHtfuQqTx6e7oSQokrqhLMD8LQ=="
        let view = ItemTypeListView { [unowned self] itemType in
            dismissTopMostViewController {
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
                // 70 per row + nav bar height
                CGFloat(ItemType.allCases.count) * 70 + 100
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
    func homepageViewModelWantsToCreateNewItem() {
        presentCreateItemView()
    }

    func homepageViewModelWantsToSearch() {
        let viewModel = SearchViewModel(symmetricKey: symmetricKey,
                                        itemRepository: itemRepository,
                                        vaults: [],
                                        preferences: preferences,
                                        logManager: logManager)
        viewModel.delegate = self
        searchViewModel = viewModel
        let viewController = UIHostingController(rootView: SearchView(viewModel: viewModel))
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func homepageViewModelWantsToPresentVaultList() {
        print(#function)
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
        print(#function)
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        print(#function)
    }

    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        print(#function)
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

// MARK: - SearchViewModelDelegate
extension HomepageCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func searchViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func searchViewModelWantsToDismiss() {
        dismissTopMostViewController()
    }

    func searchViewModelWantsToShowItemDetail(_ item: ItemContent) {
        print(#function)
    }

    func searchViewModelWantsToEditItem(_ item: ItemContent) {
        print(#function)
    }

    func searchViewModelWantsToCopy(text: String, bannerMessage: String) {
        print(#function)
    }

    func searchViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        print(#function)
    }

    func searchViewModelDidFail(_ error: Error) {
        print(#function)
    }
}
