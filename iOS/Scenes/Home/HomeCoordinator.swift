//
// HomeCoordinator.swift
// Proton Pass - Created on 02/07/2022.
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
import CoreData
import CryptoKit
import MBProgressHUD
import ProtonCore_AccountDeletion
import ProtonCore_Login
import ProtonCore_Services
import SideMenuSwift
import SwiftUI
import UIComponents
import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSignOut()
    func homeCoordinatorRequestsBiometricAuthentication()
}

final class HomeCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private let sessionData: SessionData
    private let apiService: APIService
    private let symmetricKey: SymmetricKey
    private let shareRepository: ShareRepositoryProtocol
    private let vaultItemKeysRepository: VaultItemKeysRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let publicKeyRepository: PublicKeyRepositoryProtocol
    private let credentialManager: CredentialManagerProtocol
    private let preferences: Preferences
    private let urlOpener: UrlOpener
    private let clipboardManager: ClipboardManager
    private let logManager: LogManager
    private let logger: Logger
    private var detailCoordinator: Coordinator?
    weak var delegate: HomeCoordinatorDelegate?

    var rootViewController: UIViewController { sideMenuController }
    private var topMostViewController: UIViewController {
        sideMenuController.topMostViewController
    }

    // Side menu
    private lazy var sideMenuWidth = calculateSideMenuWidth()
    private lazy var sideMenuController = provideSideMenuController()
    private lazy var sidebarViewController = provideSidebarViewController()

    // Banner
    private lazy var bannerManager = provideBannerManager()

    // Cover view
    private lazy var appContentCoverViewController = UIHostingController(rootView: AppContentCoverView())

    // My vaults
    let vaultSelection: VaultSelection
    private lazy var myVaultsCoordinator = provideMyVaultsCoordinator()
    private var myVaultsRootViewController: UIViewController { myVaultsCoordinator.rootViewController }

    // Settings
    private lazy var settingsCoordinator = provideSettingsCoordinator()
    private var settingsRootViewController: UIViewController { settingsCoordinator.rootViewController }

    // Trash
    private lazy var trashCoordinator = provideTrashCoordinator()
    private var trashRootViewController: UIViewController { trashCoordinator.rootViewController }

    private let eventLoop: SyncEventLoop

    private var cancellables = Set<AnyCancellable>()

    #warning("Try to simplify this function")
    // swiftlint:disable:next function_body_length
    init(sessionData: SessionData,
         apiService: APIService,
         symmetricKey: SymmetricKey,
         container: NSPersistentContainer,
         credentialManager: CredentialManagerProtocol,
         preferences: Preferences,
         logManager: LogManager) {
        self.sessionData = sessionData
        self.apiService = apiService
        self.symmetricKey = symmetricKey

        let userId = sessionData.userData.user.ID
        let authCredential = sessionData.userData.credential

        let itemRepository = ItemRepository(userData: sessionData.userData,
                                            symmetricKey: symmetricKey,
                                            container: container,
                                            apiService: apiService,
                                            logManager: logManager)
        self.itemRepository = itemRepository
        self.aliasRepository = AliasRepository(authCredential: authCredential, apiService: apiService)
        self.publicKeyRepository = PublicKeyRepository(container: container,
                                                       apiService: apiService,
                                                       logManager: logManager)
        let vaultItemKeysRepository = VaultItemKeysRepository(container: container,
                                                              authCredential: authCredential,
                                                              apiService: apiService,
                                                              logManager: logManager)
        self.vaultItemKeysRepository = vaultItemKeysRepository
        let shareRepository = ShareRepository(
            userData: sessionData.userData,
            localShareDatasource: LocalShareDatasource(container: container),
            remoteShareDatasouce: RemoteShareDatasource(authCredential: authCredential,
                                                        apiService: apiService),
            vaultItemKeysRepository: vaultItemKeysRepository,
            logManager: logManager)
        self.shareRepository = shareRepository
        itemRepository.delegate = credentialManager as? ItemRepositoryDelegate
        self.credentialManager = credentialManager
        self.vaultSelection = .init(vaults: [])
        self.preferences = preferences
        self.logManager = logManager
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.urlOpener = .init(preferences: preferences)
        self.clipboardManager = .init(preferences: preferences)

        let shareEventIDRepository = ShareEventIDRepository(container: container,
                                                            authCredential: authCredential,
                                                            apiService: apiService,
                                                            logManager: logManager)
        let remoteSyncEventsDatasource = RemoteSyncEventsDatasource(authCredential: authCredential,
                                                                    apiService: apiService)
        self.eventLoop = .init(userId: userId,
                               shareRepository: shareRepository,
                               shareEventIDRepository: shareEventIDRepository,
                               remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                               itemRepository: itemRepository,
                               vaultItemKeysRepository: vaultItemKeysRepository,
                               logManager: logManager)
        self.eventLoop.delegate = self
        self.eventLoop.start()
        self.setUpSideMenuPreferences()
        self.observeForegroundEntrance()
        self.observePreferences()
        self.updateSideMenuUserInterfaceStyle()
        self.myVaultsCoordinator.bannerManager = bannerManager
    }

    func onboardIfNecessary(force: Bool) {
        if !force, preferences.onboarded { return }
        let onboardingViewModel = OnboardingViewModel(credentialManager: credentialManager,
                                                      preferences: preferences,
                                                      bannerManager: bannerManager)
        let onboardingView = OnboardingView(viewModel: onboardingViewModel)
        let onboardingViewController = UIHostingController(rootView: onboardingView)
        onboardingViewController.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
        onboardingViewController.isModalInPresentation = true
        rootViewController.topMostViewController.present(onboardingViewController, animated: true)
    }
}

// MARK: - Initialization additional set ups
private extension HomeCoordinator {
    func setUpSideMenuPreferences() {
        SideMenuController.preferences.basic.menuWidth = sideMenuWidth
        SideMenuController.preferences.basic.position = .sideBySide
        SideMenuController.preferences.basic.enablePanGesture = true
        SideMenuController.preferences.basic.enableRubberEffectWhenPanning = false
        SideMenuController.preferences.animation.shouldAddShadowWhenRevealing = true
        SideMenuController.preferences.animation.shadowColor = .black
        SideMenuController.preferences.animation.shadowAlpha = 0.52
        SideMenuController.preferences.animation.revealDuration = 0.25
        SideMenuController.preferences.animation.hideDuration = 0.25
    }

    func observeForegroundEntrance() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [unowned self] _ in
                delegate?.homeCoordinatorRequestsBiometricAuthentication()
                eventLoop.forceSync()
                Task {
                    do {
                        try await credentialManager.insertAllCredentials(from: itemRepository,
                                                                         symmetricKey: symmetricKey,
                                                                         forceRemoval: false)
                    } catch {
                        logger.error(error)
                    }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIScene.didActivateNotification)
            .sink { [unowned self] _ in
                hideCoverView()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIScene.willDeactivateNotification)
            .sink { [unowned self] _ in
                showCoverView()
            }
            .store(in: &cancellables)
    }

    func observePreferences() {
        preferences.objectWillChange
            .sink { [unowned self] _ in
                self.updateSideMenuUserInterfaceStyle()
            }
            .store(in: &cancellables)
    }

    func updateSideMenuUserInterfaceStyle() {
        UIView.transition(with: rootViewController.view.window ?? rootViewController.view,
                          duration: 0.3,
                          options: .transitionCrossDissolve) {
            self.sideMenuController.overrideUserInterfaceStyle = self.preferences.theme.userInterfaceStyle
        }
    }
}

// MARK: - Lazy var providers
private extension HomeCoordinator {
    func calculateSideMenuWidth() -> CGFloat {
        if UIDevice.current.isIpad {
            return 327
        } else {
            let bounds = UIScreen.main.bounds
            let minEdge = min(bounds.width, bounds.height)
            return minEdge * 4 / 5
        }
    }

    func provideSideMenuController() -> SideMenuController {
        let sideMenuController = SideMenuController(contentViewController: myVaultsRootViewController,
                                                    menuViewController: sidebarViewController)
        sideMenuController.delegate = self
        urlOpener.rootViewController = sideMenuController
        return sideMenuController
    }

    func provideSidebarViewController() -> UIViewController {
        let sideBarViewModel = SideBarViewModel(user: sessionData.userData.user)
        sideBarViewModel.delegate = self
        myVaultsCoordinator.itemCountDelegate = sideBarViewModel
        let sidebarView = SidebarView(viewModel: sideBarViewModel, width: sideMenuWidth)
        return UIHostingController(rootView: sidebarView)
    }

    func provideBannerManager() -> BannerManager {
        let bannerManager = BannerManager(container: sideMenuController)
        self.clipboardManager.bannerManager = bannerManager
        return bannerManager
    }

    func provideMyVaultsCoordinator() -> MyVaultsCoordinator {
        let myVaultsCoordinator = MyVaultsCoordinator(symmetricKey: symmetricKey,
                                                      userData: sessionData.userData,
                                                      vaultSelection: vaultSelection,
                                                      shareRepository: shareRepository,
                                                      itemRepository: itemRepository,
                                                      aliasRepository: aliasRepository,
                                                      publicKeyRepository: publicKeyRepository,
                                                      credentialManager: credentialManager,
                                                      syncEventLoop: eventLoop,
                                                      preferences: preferences)
        myVaultsCoordinator.coordinatorDelegate = self
        myVaultsCoordinator.delegate = self.trashCoordinator
        myVaultsCoordinator.urlOpener = self.urlOpener
        myVaultsCoordinator.clipboardManager = self.clipboardManager
        return myVaultsCoordinator
    }

    func provideSettingsCoordinator() -> SettingsCoordinator {
        let settingsCoordinator = SettingsCoordinator(itemRepository: itemRepository,
                                                      credentialManager: credentialManager,
                                                      symmetricKey: symmetricKey,
                                                      preferences: preferences,
                                                      logManager: logManager)
        settingsCoordinator.coordinatorDelegate = self
        settingsCoordinator.delegate = self
        return settingsCoordinator
    }

    func provideTrashCoordinator() -> TrashCoordinator {
        let trashCoordinator = TrashCoordinator(symmetricKey: symmetricKey,
                                                shareRepository: shareRepository,
                                                itemRepository: itemRepository,
                                                aliasRepository: aliasRepository,
                                                vaultSelection: vaultSelection,
                                                syncEventLoop: eventLoop)
        trashCoordinator.coordinatorDelegate = self
        trashCoordinator.delegate = self
        trashCoordinator.urlOpener = urlOpener
        trashCoordinator.clipboardManager = self.clipboardManager
        return trashCoordinator
    }
}

// MARK: - Sidebar
extension HomeCoordinator {
    func showSidebar() {
        sideMenuController.revealMenu()
    }

    private func showMyVaultsRootViewController(filterOption: ItemTypeFilterOption) {
        myVaultsCoordinator.updateFilterOption(filterOption)
        sideMenuController.setContentViewController(to: myVaultsRootViewController,
                                                    animated: true) { [unowned self] in
            self.detailCoordinator = self.myVaultsCoordinator
            self.myVaultsCoordinator.bannerManager = self.bannerManager
            self.sideMenuController.hideMenu()
        }
    }

    func handleSidebarItem(_ sidebarItem: SidebarItem) {
        switch sidebarItem {
        case .devPreviews:
            let viewModel = DevPreviewsViewModel(itemRepository: itemRepository,
                                                 preferences: preferences)
            viewModel.delegate = self
            let view = DevPreviewsView(viewModel: viewModel)
            rootViewController.present(UIHostingController(rootView: view), animated: true)
        case .settings:
            sideMenuController.setContentViewController(to: settingsRootViewController,
                                                        animated: true) { [unowned self] in
                self.detailCoordinator = self.settingsCoordinator
                self.settingsCoordinator.bannerManager = self.bannerManager
                self.sideMenuController.hideMenu()
            }
        case .trash:
            sideMenuController.setContentViewController(to: trashRootViewController,
                                                        animated: true) { [unowned self] in
                self.detailCoordinator = self.trashCoordinator
                self.trashCoordinator.bannerManager = self.bannerManager
                self.sideMenuController.hideMenu()
            }
        case .bugReport:
            if let url = URL(string: "https://proton.me/support/contact"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            sideMenuController.hideMenu()
        case .signOut:
            requestSignOutConfirmation()
        }
    }

    func showUserSwitcher() {
        print(#function)
    }

    func alert(error: Error) {
        let alert = UIAlertController(title: "Error occured",
                                      message: error.messageForTheUser,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        topMostViewController.present(alert, animated: true)
    }
}

// MARK: - Common UI operations
private extension HomeCoordinator {
    func showLoadingHud(to view: UIView? = nil) {
        MBProgressHUD.showAdded(to: view ?? topMostViewController.view, animated: true)
    }

    func hideLoadingHud(for view: UIView? = nil) {
        MBProgressHUD.hide(for: view ?? topMostViewController.view, animated: true)
    }
}

// MARK: - Cover
private extension HomeCoordinator {
    func showCoverView() {
        guard let coverView = appContentCoverViewController.view,
        let sideMenuView = sideMenuController.view else { return }
        sideMenuController.addChild(appContentCoverViewController)
        coverView.translatesAutoresizingMaskIntoConstraints = false
        sideMenuView.addSubview(coverView)
        coverView.alpha = 0.0
        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: sideMenuView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: sideMenuView.leadingAnchor),
            coverView.bottomAnchor.constraint(equalTo: sideMenuView.bottomAnchor),
            coverView.trailingAnchor.constraint(equalTo: sideMenuView.trailingAnchor)
        ])
        appContentCoverViewController.didMove(toParent: sideMenuController)
        UIView.animate(withDuration: 0.15) {
            coverView.alpha = 1.0
        }
    }

    func hideCoverView() {
        UIView.animate(
            withDuration: 0.15,
            animations: {
                self.appContentCoverViewController.view.alpha = 0.0
            },
            completion: { [unowned self] _ in
                self.appContentCoverViewController.willMove(toParent: nil)
                self.appContentCoverViewController.view.removeFromSuperview()
                self.appContentCoverViewController.removeFromParent()
            })
    }
}

// MARK: - Sign out
private extension HomeCoordinator {
    func requestSignOutConfirmation() {
        let alert = UIAlertController(title: "You will be signed out",
                                      message: "All associated data will be deleted. Please confirm.",
                                      preferredStyle: .alert)
        let signOutAction = UIAlertAction(title: "Yes, sign me out", style: .destructive) { [unowned self] _ in
            self.signOut()
        }
        alert.addAction(signOutAction)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        sideMenuController.present(alert, animated: true)
    }

    func signOut() {
        eventLoop.stop()
        delegate?.homeCoordinatorDidSignOut()
    }
}

// MARK: - SideBarViewModelDelegate
extension HomeCoordinator: SideBarViewModelDelegate {
    func sideBarViewModelWantsToShowUsersSwitcher() {
        showUserSwitcher()
    }

    func sideBarViewModelWantsToHandleItem(_ item: SidebarItem) {
        handleSidebarItem(item)
    }

    func sideBarViewModelWantsToShowAllItems() {
        showMyVaultsRootViewController(filterOption: .all)
    }

    func sideBarViewModelWantsToShowItems(ofType type: ItemContentType) {
        showMyVaultsRootViewController(filterOption: .filtered(type))
    }
}

// MARK: - CoordinatorDelegate
extension HomeCoordinator: CoordinatorDelegate {
    func coordinatorWantsToToggleSidebar() {
        showSidebar()
    }

    func coordinatorWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func coordinatorWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func coordinatorWantsToAlertError(_ error: Error) {
        alert(error: error)
    }
}

// MARK: - SyncEventLoopDelegate
extension HomeCoordinator: SyncEventLoopDelegate {
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
            myVaultsCoordinator.refreshItems()
            trashCoordinator.refreshTrashedItems()
        } else {
            logger.info("Has no new events. Do nothing.")
        }
    }

    func syncEventLoopDidFailLoop(error: Error) {
        logger.error(error)
        bannerManager.displayTopErrorMessage(error)
    }
}

// MARK: - Account deletion
private extension HomeCoordinator {
    func beginAccountDeletionFlow() {
        showLoadingHud(to: rootViewController.view)
        let accountDeletion = AccountDeletionService(api: apiService)
        accountDeletion.initiateAccountDeletionProcess(
            over: self.rootViewController,
            performAfterShowingAccountDeletionScreen: { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.hideLoadingHud(for: self.rootViewController.view)
                }
            },
            completion: { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.signOut()
                    case .failure(AccountDeletionError.closedByUser):
                        break
                    case .failure(let error):
                        self.alert(error: error)
                    }
                }
            })
    }
}

// MARK: - TrashCoordinatorDelegate
extension HomeCoordinator: TrashCoordinatorDelegate {
    func trashCoordinatorDidRestoreItems() {
        myVaultsCoordinator.refreshItems()
    }
}

// MARK: - SettingsCoordinatorDelegate
extension HomeCoordinator: SettingsCoordinatorDelegate {
    func settingsCoordinatorWantsToDeleteAccount() {
        beginAccountDeletionFlow()
    }

    func settingsCoordinatorDidFinishFullSync() {
        myVaultsCoordinator.refreshItems()
        trashCoordinator.refreshTrashedItems()
        bannerManager.displayBottomInfoMessage("Fully synchronized")
    }
}

// MARK: - SideMenuControllerDelegate
extension HomeCoordinator: SideMenuControllerDelegate {
    func sideMenuControllerWillRevealMenu(_ sideMenuController: SideMenuController) {
        self.detailCoordinator?.setStatusBarStyle(.lightContent)
    }

    func sideMenuControllerWillHideMenu(_ sideMenuController: SideMenuController) {
        self.detailCoordinator?.setStatusBarStyle(.default)
    }
}

// MARK: - DevPreviewsViewModelDelegate
extension HomeCoordinator: DevPreviewsViewModelDelegate {
    func devPreviewsViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func devPreviewsViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func devPreviewsViewModelWantsToOnboard() {
        onboardIfNecessary(force: true)
    }

    func devPreviewsViewModelWantsToEnableAutoFill() {
        myVaultsCoordinator.vaultContentViewModelWantsToEnableAutoFill()
    }

    func devPreviewsViewModelDidTrashAllItems(count: Int) {
        myVaultsCoordinator.refreshItems()
        trashCoordinator.refreshTrashedItems()
        bannerManager.displayBottomInfoMessage("\(count) item(s) sent to trash")
    }

    func devPreviewsViewModelDidFail(_ error: Error) {
        alert(error: error)
    }
}

extension BannerManager {
    func displayTopErrorMessage(_ error: Error) {
        displayTopErrorMessage(error.messageForTheUser)
    }
}
