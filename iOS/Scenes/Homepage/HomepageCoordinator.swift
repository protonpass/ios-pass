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
import ProtonCore_AccountDeletion
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
    private let apiService: APIService
    private let clipboardManager: ClipboardManager
    private let credentialManager: CredentialManagerProtocol
    private let eventLoop: SyncEventLoop
    private let favIconRepository: FavIconRepositoryProtocol
    private let itemContextMenuHandler: ItemContextMenuHandler
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let logManager: LogManager
    private let manualLogIn: Bool
    private let preferences: Preferences
    private let primaryPlan: PlanLite?
    private let searchEntryDatasource: LocalSearchEntryDatasourceProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let urlOpener: UrlOpener
    private let userData: UserData
    private let vaultsManager: VaultsManager

    // Lazily initialized properties
    private lazy var bannerManager: BannerManager = { .init(container: rootViewController) }()

    // References
    private weak var profileTabViewModel: ProfileTabViewModel?
    private weak var currentItemDetailViewModel: BaseItemDetailViewModel?
    private weak var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private weak var searchViewModel: SearchViewModel?

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: HomepageCoordinatorDelegate?
    weak var homepageTabDelegete: HomepageTabDelegete?

    // swiftlint:disable:next function_body_length
    init(apiService: APIService,
         container: NSPersistentContainer,
         credentialManager: CredentialManagerProtocol,
         domainParser: DomainParser,
         logManager: LogManager,
         manualLogIn: Bool,
         preferences: Preferences,
         primaryPlan: PlanLite?,
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
                                                    logManager: logManager,
                                                    symmetricKey: symmetricKey,
                                                    userData: userData)
        let shareEventIDRepository = ShareEventIDRepository(container: container,
                                                            apiService: apiService,
                                                            logManager: logManager)
        let shareRepository = ShareRepository(symmetricKey: symmetricKey,
                                              userData: userData,
                                              container: container,
                                              apiService: apiService,
                                              logManager: logManager)

        self.aliasRepository = AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
        self.apiService = apiService
        self.clipboardManager = .init(preferences: preferences)
        self.credentialManager = credentialManager
        self.eventLoop = .init(userId: userData.user.ID,
                               shareRepository: shareRepository,
                               shareEventIDRepository: shareEventIDRepository,
                               remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                               itemRepository: itemRepository,
                               shareKeyRepository: shareKeyRepository,
                               logManager: logManager)
        self.favIconRepository = FavIconRepository(apiService: apiService,
                                                   containerUrl: URL.favIconsContainerURL(),
                                                   cacheExpirationDays: 14,
                                                   domainParser: domainParser,
                                                   symmetricKey: symmetricKey)
        self.itemContextMenuHandler = .init(clipboardManager: clipboardManager,
                                            itemRepository: itemRepository,
                                            logManager: logManager)
        self.itemRepository = itemRepository
        self.logger = .init(manager: logManager)
        self.logManager = logManager
        self.manualLogIn = manualLogIn
        self.preferences = preferences
        self.primaryPlan = primaryPlan
        self.searchEntryDatasource = LocalSearchEntryDatasource(container: container)
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
        self.urlOpener = .init(preferences: preferences)
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
        (itemRepository as? ItemRepository)?.delegate = credentialManager as? CredentialManager
        urlOpener.rootViewController = rootViewController

        preferences.objectWillChange
            .sink { [unowned self] _ in
                self.rootViewController.overrideUserInterfaceStyle = self.preferences.theme.userInterfaceStyle
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [unowned self] _ in
                refresh()
                eventLoop.forceSync()
                Task {
                    do {
                        try await credentialManager.insertAllCredentials(from: itemRepository,
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
        let itemsTabViewModel = ItemsTabViewModel(favIconRepository: favIconRepository,
                                                  itemContextMenuHandler: itemContextMenuHandler,
                                                  itemRepository: itemRepository,
                                                  logManager: logManager,
                                                  preferences: preferences,
                                                  syncEventLoop: eventLoop,
                                                  vaultsManager: vaultsManager)
        itemsTabViewModel.delegate = self
        itemsTabViewModel.emptyVaultViewModelDelegate = self

        let profileTabViewModel = ProfileTabViewModel(apiService: apiService,
                                                      credentialManager: credentialManager,
                                                      itemRepository: itemRepository,
                                                      primaryPlan: primaryPlan,
                                                      preferences: preferences,
                                                      logManager: logManager,
                                                      vaultsManager: vaultsManager)
        profileTabViewModel.delegate = self

        let placeholderView = ItemDetailPlaceholderView(theme: preferences.theme) { [unowned self] in
            self.popTopViewController(animated: true)
        }

        start(with: HomepageTabbarView(itemsTabViewModel: itemsTabViewModel,
                                       profileTabViewModel: profileTabViewModel,
                                       homepageCoordinator: self,
                                       delegate: self).ignoresSafeArea(edges: [.top, .bottom]),
              secondaryView: placeholderView)
        rootViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        self.profileTabViewModel = profileTabViewModel
    }

    func informAliasesLimit() {
        bannerManager.displayTopErrorMessage("You can not create more aliases.")
    }

    func present<V: View>(_ view: V, animated: Bool = true, dismissible: Bool = true) {
        present(UIHostingController(rootView: view),
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                animated: animated,
                dismissible: dismissible)
    }

    func present(_ viewController: UIViewController, animated: Bool = true, dismissible: Bool = true) {
        present(viewController,
                userInterfaceStyle: preferences.theme.userInterfaceStyle,
                animated: animated,
                dismissible: dismissible)
    }

    func presentItemDetailView(for itemContent: ItemContent, asSheet: Bool) {
        // Only show vault when there're more than 1 vault
        var vault: Vault?
        let allVaults = vaultsManager.getAllVaults()
        if allVaults.count > 1 {
            vault = allVaults.first(where: { $0.shareId == itemContent.shareId })
        }

        let itemDetailPage: ItemDetailPage
        switch itemContent.contentData {
        case .login:
            itemDetailPage = makeLoginItemDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        case .note:
            itemDetailPage = makeNoteDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        case .alias:
            itemDetailPage = makeAliasItemDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        }

        itemDetailPage.viewModel.delegate = self
        currentItemDetailViewModel = itemDetailPage.viewModel

        if asSheet {
            present(itemDetailPage.view)
        } else {
            push(itemDetailPage.view)
        }
    }

    func presentEditItemView(for itemContent: ItemContent) {
        do {
            let mode = ItemMode.edit(itemContent)
            switch itemContent.contentData.type {
            case .login:
                try presentCreateEditLoginView(mode: mode)
            case .note:
                try presentCreateEditNoteView(mode: mode)
            case .alias:
                try presentCreateEditAliasView(mode: mode)
            }
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func presentItemTypeListView() {
        let view = ItemTypeListView { [unowned self] itemType in
            dismissTopMostViewController { [unowned self] in
                self.presentCreateItemView(for: itemType)
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
        present(viewController)
    }

    func presentCreateItemView(for itemType: ItemType) {
        guard let shareId = vaultsManager.getSelectedShareId() else { return }
        do {
            switch itemType {
            case .login:
                let logInType = ItemCreationType.login(title: nil, url: nil, autofill: false)
                try self.presentCreateEditLoginView(mode: .create(shareId: shareId, type: logInType))
            case .alias:
                try self.presentCreateEditAliasView(mode: .create(shareId: shareId, type: .alias))
            case .note:
                try self.presentCreateEditNoteView(mode: .create(shareId: shareId, type: .other))
            case .password:
                self.presentGeneratePasswordView(delegate: self, mode: .random)
            }
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func presentCreateEditLoginView(mode: ItemMode) throws {
        let emailAddress = userData.addresses.first?.email ?? ""
        let viewModel = try CreateEditLoginViewModel(mode: mode,
                                                     itemRepository: itemRepository,
                                                     aliasRepository: aliasRepository,
                                                     vaults: vaultsManager.getAllVaults(),
                                                     preferences: preferences,
                                                     logManager: logManager,
                                                     emailAddress: emailAddress)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        present(view, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentCreateEditAliasView(mode: ItemMode) throws {
        let viewModel = try CreateEditAliasViewModel(mode: mode,
                                                     itemRepository: itemRepository,
                                                     aliasRepository: aliasRepository,
                                                     vaults: vaultsManager.getAllVaults(),
                                                     preferences: preferences,
                                                     logManager: logManager)
        viewModel.delegate = self
        viewModel.createEditAliasViewModelDelegate = self
        let view = CreateEditAliasView(viewModel: viewModel)
        present(view, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentMailboxSelectionView(selection: MailboxSelection, mode: MailboxSelectionView.Mode) {
        let view = MailboxSelectionView(mailboxSelection: selection, mode: mode)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(viewController)
    }

    func presentCreateEditNoteView(mode: ItemMode) throws {
        let viewModel = try CreateEditNoteViewModel(mode: mode,
                                                    itemRepository: itemRepository,
                                                    vaults: vaultsManager.getAllVaults(),
                                                    preferences: preferences,
                                                    logManager: logManager)
        viewModel.delegate = self
        let view = CreateEditNoteView(viewModel: viewModel)
        present(view, dismissible: false)
        currentCreateEditItemViewModel = viewModel
    }

    func presentGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate?,
                                     mode: GeneratePasswordViewMode) {
        let viewModel = GeneratePasswordViewModel(mode: mode)
        viewModel.delegate = delegate
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController)
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
        present(viewController)
    }

    func presentCreateEditVaultView(mode: VaultMode) {
        let viewModel = CreateEditVaultViewModel(mode: mode,
                                                 shareRepository: shareRepository,
                                                 logManager: logManager,
                                                 theme: preferences.theme)
        viewModel.delegate = self
        let view = CreateEditVaultView(viewModel: viewModel)
        present(view)
    }

    func refresh() {
        vaultsManager.refresh()
        searchViewModel?.refreshResults()
        currentItemDetailViewModel?.refresh()
        currentCreateEditItemViewModel?.refresh()
    }

    func adaptivelyPresentDetailView<V: View>(view: V) {
        if UIDevice.current.isIpad {
            push(view)
        } else {
            present(view, userInterfaceStyle: preferences.theme.userInterfaceStyle)
        }
    }

    func adaptivelyDismissCurrentDetailView() {
        // Dismiss differently because show differently
        // (push on iPad, sheets on iPhone)
        if UIDevice.current.isIpad {
            popTopViewController(animated: true)
        } else {
            dismissTopMostViewController()
        }
    }

    func presentLogsView(for module: PassLogModule) {
        let viewModel = LogsViewModel(module: module)
        viewModel.delegate = self
        let view = LogsView(viewModel: viewModel)
        present(view)
    }
}

// MARK: - Item detail pages
private extension HomepageCoordinator {
    struct ItemDetailPage {
        let viewModel: BaseItemDetailViewModel
        let view: any View
    }

    func makeLoginItemDetailPage(from itemContent: ItemContent,
                                 asSheet: Bool,
                                 vault: Vault?) -> ItemDetailPage {
        let viewModel = LogInDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             favIconRepository: favIconRepository,
                                             itemRepository: itemRepository,
                                             vault: vault,
                                             logManager: logManager,
                                             theme: preferences.theme)
        viewModel.logInDetailViewModelDelegate = self
        return .init(viewModel: viewModel, view: LogInDetailView(viewModel: viewModel))
    }

    func makeAliasItemDetailPage(from itemContent: ItemContent,
                                 asSheet: Bool,
                                 vault: Vault?) -> ItemDetailPage {
        let viewModel = AliasDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             favIconRepository: favIconRepository,
                                             itemRepository: itemRepository,
                                             aliasRepository: aliasRepository,
                                             vault: vault,
                                             logManager: logManager,
                                             theme: preferences.theme)
        return .init(viewModel: viewModel, view: AliasDetailView(viewModel: viewModel))
    }

    func makeNoteDetailPage(from itemContent: ItemContent,
                            asSheet: Bool,
                            vault: Vault?) -> ItemDetailPage {
        let viewModel = NoteDetailViewModel(isShownAsSheet: asSheet,
                                            itemContent: itemContent,
                                            favIconRepository: favIconRepository,
                                            itemRepository: itemRepository,
                                            vault: vault,
                                            logManager: logManager,
                                            theme: preferences.theme)
        return .init(viewModel: viewModel, view: NoteDetailView(viewModel: viewModel))
    }
}

// MARK: - Public APIs
extension HomepageCoordinator {
    func onboardIfNecessary() {
        if preferences.onboarded { return }
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

// MARK: - HomepageTabBarControllerDelegate
extension HomepageCoordinator: HomepageTabBarControllerDelegate {
    func homepageTabBarControllerDidSelectItemsTab() {
        if !isCollapsed() {
            let placeholderView = ItemDetailPlaceholderView(theme: preferences.theme) { [unowned self] in
                self.popTopViewController(animated: true)
            }
            push(placeholderView)
        }
    }

    func homepageTabBarControllerWantToCreateNewItem() {
        presentItemTypeListView()
    }

    func homepageTabBarControllerDidSelectProfileTab() {
        if !isCollapsed() {
            profileTabViewModelWantsToShowAccountMenu()
        }
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

    func itemsTabViewModelWantsToSearch(vaultSelection: VaultSelection) {
        let viewModel = SearchViewModel(itemContextMenuHandler: itemContextMenuHandler,
                                        itemRepository: itemRepository,
                                        logManager: logManager,
                                        searchEntryDatasource: searchEntryDatasource,
                                        shareRepository: shareRepository,
                                        symmetricKey: symmetricKey,
                                        vaultSelection: vaultSelection)
        viewModel.delegate = self
        searchViewModel = viewModel
        let view = SearchView(viewModel: viewModel)
        present(view)
    }

    func itemsTabViewModelWantsToPresentVaultList(vaultsManager: VaultsManager) {
        let viewModel = EditableVaultListViewModel(vaultsManager: vaultsManager,
                                                   logManager: logManager)
        viewModel.delegate = self
        let view = EditableVaultListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            // Num of vaults + all items + trash + create vault button
            let height = CGFloat(66 * vaultsManager.getVaultCount() + 66 + 66 + 120)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent, .large()]
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
        presentItemDetailView(for: itemContent, asSheet: !UIDevice.current.isIpad)
    }

    func itemsTabViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - EmptyVaultViewModelDelegate
extension HomepageCoordinator: EmptyVaultViewModelDelegate {
    func emptyVaultViewModelWantsToCreateLoginItem() {
        presentCreateItemView(for: .login)
    }

    func emptyVaultViewModelWantsToCreateAliasItem() {
        presentCreateItemView(for: .alias)
    }

    func emptyVaultViewModelWantsToCreateNoteItem() {
        presentCreateItemView(for: .note)
    }
}

// MARK: - ProfileTabViewModelDelegate
extension HomepageCoordinator: ProfileTabViewModelDelegate {
    func profileTabViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func profileTabViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func profileTabViewModelWantsToShowAccountMenu() {
        let viewModel = AccountViewModel(apiService: apiService,
                                         logManager: logManager,
                                         primaryPlan: primaryPlan,
                                         theme: preferences.theme,
                                         username: userData.user.email ?? "")
        viewModel.delegate = self
        let view = AccountView(viewModel: viewModel)
        adaptivelyPresentDetailView(view: view)
    }

    func profileTabViewModelWantsToShowSettingsMenu() {
        let viewModel = SettingsViewModel(logManager: logManager,
                                          preferences: preferences,
                                          vaultsManager: vaultsManager)
        viewModel.delegate = self
        let view = SettingsView(viewModel: viewModel)
        adaptivelyPresentDetailView(view: view)
    }

    func profileTabViewModelWantsToShowAcknowledgments() {
        print(#function)
    }

    func profileTabViewModelWantsToShowPrivacyPolicy() {
        urlOpener.open(urlString: "https://proton.me/legal/privacy")
    }

    func profileTabViewModelWantsToShowTermsOfService() {
        urlOpener.open(urlString: "https://proton.me/legal/terms")
    }

    func profileTabViewModelWantsToShowTips() {
        print(#function)
    }

    func profileTabViewModelWantsToShowFeedback() {
        let view = FeedbackChannelsView { [unowned self] selectedChannel in
            self.urlOpener.open(urlString: selectedChannel.urlString)
        }
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = CGFloat(52 * FeedbackChannel.allCases.count + 80)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController)
    }

    func profileTabViewModelWantsToRateApp() {
        urlOpener.open(urlString: kAppStoreUrlString)
    }

    func profileTabViewModelWantsToQaFeatures() {
        let viewModel = QAFeaturesViewModel(credentialManager: credentialManager,
                                            favIconRepository: favIconRepository,
                                            preferences: preferences,
                                            bannerManager: bannerManager,
                                            logManager: logManager)
        let view = QAFeaturesView(viewModel: viewModel)
        present(view)
    }

    func profileTabViewModelWantsDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - AccountViewModelDelegate
extension HomepageCoordinator: AccountViewModelDelegate {
    func accountViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func accountViewModelWantsToManageSubscription() {
        print(#function)
    }

    func accountViewModelWantsToSignOut() {
        eventLoop.stop()
        delegate?.homepageCoordinatorWantsToLogOut()
    }

    func accountViewModelWantsToDeleteAccount() {
        let accountDeletion = AccountDeletionService(api: apiService)
        let view = topMostViewController.view
        showLoadingHud(view)
        accountDeletion.initiateAccountDeletionProcess(
            over: topMostViewController,
            performAfterShowingAccountDeletionScreen: { [weak self] in
                self?.hideLoadingHud(view)
            },
            completion: { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.accountViewModelWantsToSignOut()
                    case .failure(AccountDeletionError.closedByUser):
                        break
                    case .failure(let error):
                        self.bannerManager.displayTopErrorMessage(error)
                    }
                }
            })
    }
}

// MARK: - SettingsViewModelDelegate
extension HomepageCoordinator: SettingsViewModelDelegate {
    func settingsViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func settingsViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func settingsViewModelWantsToGoBack() {
        adaptivelyDismissCurrentDetailView()
    }

    func settingsViewModelWantsToEditDefaultBrowser(supportedBrowsers: [Browser]) {
        let view = EditDefaultBrowserView(supportedBrowsers: supportedBrowsers, preferences: preferences)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.short.value) * supportedBrowsers.count + 140
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController)
    }

    func settingsViewModelWantsToEditTheme() {
        let view = EditThemeView(preferences: preferences)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.short.value) * Theme.allCases.count + 100
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController)
    }

    func settingsViewModelWantsToEditClipboardExpiration() {
        let view = EditClipboardExpirationView(preferences: preferences)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.short.value) * ClipboardExpiration.allCases.count + 100
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController)
    }

    func settingsViewModelWantsToEdit(primaryVault: Vault) {
        let allVaults = vaultsManager.getAllVaultContents().map { VaultListUiModel(vaultContent: $0) }
        let viewModel = EditPrimaryVaultViewModel(allVaults: allVaults,
                                                  primaryVault: primaryVault,
                                                  shareRepository: shareRepository)
        viewModel.delegate = self
        let view = EditPrimaryVaultView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.medium.value) * vaultsManager.getVaultCount() + 100
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController)
    }

    func settingsViewModelWantsToViewLogs() {
        let view = LogTypesView(
            onSelect: { [unowned self] module in
                self.presentLogsView(for: module)
            },
            onClear: { [unowned self] in
                self.bannerManager.displayBottomSuccessMessage("All logs cleared")
            })
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.short.value) * 4 + 120
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController)
    }

    func settingsViewModelDidFinishFullSync() {
        refresh()
        bannerManager.displayBottomSuccessMessage("Force synchronization done")
    }

    func settingsViewModelDidEncounter(error: Error) {
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

    func createEditItemViewModelWantsToChangeVault(selectedVault: Vault,
                                                   delegate: VaultSelectorViewModelDelegate) {
        let vaultContents = vaultsManager.getAllVaultContents()
        let viewModel = VaultSelectorViewModel(allVaults: vaultContents.map { .init(vaultContent: $0) },
                                               selectedVault: selectedVault)
        viewModel.delegate = delegate
        let view = VaultSelectorView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = CGFloat(66 * vaultsManager.getVaultCount() + 100)
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                height
            }
            viewController.sheetPresentationController?.detents = [customDetent, .large()]
        } else {
            viewController.sheetPresentationController?.detents = [.medium(), .large()]
        }
        present(viewController)
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
        homepageTabDelegete?.homepageTabShouldChange(tab: .items)
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
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        viewModel.delegate = self
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        present(viewController)
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
        let handler = DeleteVaultAlertHandler(rootViewController: topMostViewController,
                                              vault: vault,
                                              delegate: delegate)
        handler.showAlert()
    }

    func editableVaultListViewModelDidDelete(vault: Vault) {
        bannerManager.displayBottomInfoMessage("Vault \"\(vault.name)\" deleted")
        vaultsManager.refresh()
    }

    func editableVaultListViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }

    func editableVaultListViewModelDidRestoreAllTrashedItems() {
        bannerManager.displayBottomSuccessMessage("All items restored")
        refresh()
    }

    func editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems() {
        bannerManager.displayBottomInfoMessage("All items permanently deleted")
        refresh()
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

    func itemDetailViewModelWantsToGoBack(isShownAsSheet: Bool) {
        if isShownAsSheet {
            dismissTopMostViewController()
        } else {
            popTopViewController(animated: true)
        }
    }

    func itemDetailViewModelWantsToEditItem(_ itemContent: ItemContent) {
        presentEditItemView(for: itemContent)
    }

    func itemDetailViewModelWantsToCopy(text: String, bannerMessage: String) {
        clipboardManager.copy(text: text, bannerMessage: bannerMessage)
    }

    func itemDetailViewModelWantsToShowFullScreen(_ text: String) {
        showFullScreen(text: text,
                       theme: preferences.theme,
                       userInterfaceStyle: preferences.theme.userInterfaceStyle)
    }

    func itemDetailViewModelWantsToOpen(urlString: String) {
        urlOpener.open(urlString: urlString)
    }

    func itemDetailViewModelDidMove(item: ItemTypeIdentifiable, to vault: Vault) {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage("Item moved to vault \"\(vault.name)\"")
        }
        refresh()
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
        refresh()
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
        refresh()
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage(item.type.restoreMessage)
        }
    }

    func itemDetailViewModelDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        refresh()
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
        presentItemDetailView(for: itemContent, asSheet: true)
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
        refresh()
    }

    func itemContextMenuHandlerDidUntrash(item: ItemTypeIdentifiable) {
        refresh()
    }

    func itemContextMenuHandlerDidPermanentlyDelete(item: ItemTypeIdentifiable) {
        refresh()
    }
}

// MARK: - SearchViewModelDelegate
extension HomepageCoordinator: SearchViewModelDelegate {
    func searchViewModelWantsToViewDetail(of itemContent: Client.ItemContent) {
        presentItemDetailView(for: itemContent, asSheet: true)
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
        vaultsManager.refresh()
    }

    func createEditVaultViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - EditPrimaryVaultViewModelDelegate
extension HomepageCoordinator: EditPrimaryVaultViewModelDelegate {
    func editPrimaryVaultViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func editPrimaryVaultViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func editPrimaryVaultViewModelDidUpdatePrimaryVault() {
        dismissTopMostViewController(animated: true) { [unowned self] in
            self.bannerManager.displayBottomSuccessMessage("Primary vault updated")
        }
        vaultsManager.refresh()
    }

    func editPrimaryVaultViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - LogsViewModelDelegate
extension HomepageCoordinator: LogsViewModelDelegate {
    func logsViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func logsViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func logsViewModelWantsToShareLogs(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityVC)
    }

    func logsViewModelDidEncounter(error: Error) {
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
            refresh()
        } else {
            logger.info("Has no new events. Do nothing.")
        }
    }

    func syncEventLoopDidFailLoop(error: Error) {
        // Silently fail & not show error to users
        logger.error(error)
    }
}

private extension URL {
    static func favIconsContainerURL() -> URL {
        guard let fileContainer = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroup) else {
            fatalError("Can not create folder for fav icons")
        }
        return fileContainer.appendingPathComponent("FavIcons", isDirectory: true)
    }
}
