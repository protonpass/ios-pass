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
import ProtonCore_Login
import ProtonCore_Services
import SideMenuSwift
import SwiftUI
import UIComponents
import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSignOut()
    func homeCoordinatorRequestsLocalAuthentication()
}

// swiftlint:disable:next todo
// TODO: Make width dynamic based on screen orientation
private let kMenuWidth = UIScreen.main.bounds.width * 4 / 5

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
    weak var delegate: HomeCoordinatorDelegate?

    var rootViewController: UIViewController { sideMenuController }
    private var topMostViewController: UIViewController {
        sideMenuController.presentedViewController ?? sideMenuController
    }

    // Side menu
    private lazy var sideMenuController = provideSideMenuController()
    private lazy var sidebarViewController = provideSidebarViewController()

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
         preferences: Preferences) {
        self.sessionData = sessionData
        self.apiService = apiService
        self.symmetricKey = symmetricKey

        let userId = sessionData.userData.user.ID
        let authCredential = sessionData.userData.credential

        let itemRepository = ItemRepository(userData: sessionData.userData,
                                            symmetricKey: symmetricKey,
                                            container: container,
                                            apiService: apiService)
        self.itemRepository = itemRepository
        self.aliasRepository = AliasRepository(authCredential: authCredential, apiService: apiService)
        self.publicKeyRepository = PublicKeyRepository(container: container,
                                                       apiService: apiService)
        let shareRepository = ShareRepository(userId: userId,
                                              container: container,
                                              authCredential: authCredential,
                                              apiService: apiService)
        self.shareRepository = shareRepository
        let vaultItemKeysRepository = VaultItemKeysRepository(container: container,
                                                              authCredential: authCredential,
                                                              apiService: apiService)
        self.vaultItemKeysRepository = vaultItemKeysRepository
        itemRepository.delegate = credentialManager as? ItemRepositoryDelegate
        self.credentialManager = credentialManager
        self.vaultSelection = .init(vaults: [])
        self.preferences = preferences

        let shareEventIDRepository = ShareEventIDRepository(container: container,
                                                            authCredential: authCredential,
                                                            apiService: apiService)
        let remoteSyncEventsDatasource = RemoteSyncEventsDatasource(authCredential: authCredential,
                                                                    apiService: apiService)
        self.eventLoop = .init(userId: userId,
                               shareRepository: shareRepository,
                               shareEventIDRepository: shareEventIDRepository,
                               remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                               itemRepository: itemRepository,
                               vaultItemKeysRepository: vaultItemKeysRepository)
        self.eventLoop.delegate = self
        self.eventLoop.start()
        self.setUpSideMenuPreferences()
        self.observeVaultSelection()
        self.observeForegroundEntrance()
    }
}

// MARK: - Initialization additional set ups
private extension HomeCoordinator {
    private func setUpSideMenuPreferences() {
        SideMenuController.preferences.basic.menuWidth = kMenuWidth
        SideMenuController.preferences.basic.position = .sideBySide
        SideMenuController.preferences.basic.enablePanGesture = true
        SideMenuController.preferences.basic.enableRubberEffectWhenPanning = false
        SideMenuController.preferences.animation.shouldAddShadowWhenRevealing = true
        SideMenuController.preferences.animation.shadowColor = .black
        SideMenuController.preferences.animation.shadowAlpha = 0.52
        SideMenuController.preferences.animation.revealDuration = 0.25
        SideMenuController.preferences.animation.hideDuration = 0.25
    }

    private func observeVaultSelection() {
        vaultSelection.$selectedVault
            .sink { [unowned self] _ in
                self.showMyVaultsRootViewController()
            }
            .store(in: &cancellables)
    }

    private func observeForegroundEntrance() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [unowned self] _ in
                delegate?.homeCoordinatorRequestsLocalAuthentication()
                Task {
                    do {
                        try await credentialManager.insertAllCredentials(from: itemRepository,
                                                                         symmetricKey: symmetricKey,
                                                                         forceRemoval: false)
                    } catch {
                        PPLogger.shared?.log(error)
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
}

// MARK: - Lazy var providers
private extension HomeCoordinator {
    func provideSideMenuController() -> SideMenuController {
        SideMenuController(contentViewController: myVaultsRootViewController,
                           menuViewController: sidebarViewController)
    }

    func provideSidebarViewController() -> UIViewController {
        let sideBarViewModel = SideBarViewModel(user: sessionData.userData.user)
        sideBarViewModel.delegate = self
        let sidebarView = SidebarView(viewModel: sideBarViewModel, width: kMenuWidth)
        return UIHostingController(rootView: sidebarView)
    }

    func provideMyVaultsCoordinator() -> MyVaultsCoordinator {
        let myVaultsCoordinator = MyVaultsCoordinator(symmetricKey: symmetricKey,
                                                      userData: sessionData.userData,
                                                      vaultSelection: vaultSelection,
                                                      shareRepository: shareRepository,
                                                      vaultItemKeysRepository: vaultItemKeysRepository,
                                                      itemRepository: itemRepository,
                                                      aliasRepository: aliasRepository,
                                                      publicKeyRepository: publicKeyRepository)
        myVaultsCoordinator.delegate = self
        myVaultsCoordinator.onTrashedItem = { [unowned self] in
            self.trashCoordinator.refreshTrashedItems()
        }
        return myVaultsCoordinator
    }

    func provideSettingsCoordinator() -> SettingsCoordinator {
        let settingsCoordinator = SettingsCoordinator(itemRepository: itemRepository,
                                                      credentialManager: credentialManager,
                                                      symmetricKey: symmetricKey,
                                                      preferences: preferences)
        settingsCoordinator.delegate = self
        return settingsCoordinator
    }

    func provideTrashCoordinator() -> TrashCoordinator {
        let trashCoordinator = TrashCoordinator(symmetricKey: symmetricKey,
                                                shareRepository: shareRepository,
                                                itemRepository: itemRepository)
        trashCoordinator.delegate = self
        trashCoordinator.onRestoredItem = { [unowned self] in
            self.myVaultsCoordinator.refreshItems()
        }
        return trashCoordinator
    }
}

// MARK: - Sidebar
extension HomeCoordinator {
    func showSidebar() {
        sideMenuController.revealMenu()
    }

    private func showMyVaultsRootViewController() {
        sideMenuController.setContentViewController(to: myVaultsRootViewController,
                                                    animated: true) { [unowned self] in
            self.sideMenuController.hideMenu()
        }
    }

    func handleSidebarItem(_ sidebarItem: SidebarItem) {
        switch sidebarItem {
        case .home:
            showMyVaultsRootViewController()
        case .settings:
            sideMenuController.setContentViewController(to: settingsRootViewController,
                                                        animated: true) { [unowned self] in
                self.sideMenuController.hideMenu()
            }
        case .trash:
            sideMenuController.setContentViewController(to: trashRootViewController,
                                                        animated: true) { [unowned self] in
                self.sideMenuController.hideMenu()
            }
        case .help:
            break
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
    func showLoadingHud() {
        MBProgressHUD.showAdded(to: topMostViewController.view, animated: true)
    }

    func hideLoadingHud() {
        MBProgressHUD.hide(for: topMostViewController.view, animated: true)
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
        print(#function)
    }

    func syncEventLoopDidStopLooping() {
        print(#function)
    }

    func syncEventLoopDidBeginNewLoop() {
        print(#function)
    }

    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason) {
        print(#function)
        print(reason)
    }

    func syncEventLoopDidFinishLoop(hasNewEvents: Bool) {
        print(#function)
        if hasNewEvents {
            myVaultsCoordinator.refreshItems()
        }
    }

    func syncEventLoopDidFailLoop(error: Error) {
        print(#function)
        print(error.localizedDescription)
    }
}
