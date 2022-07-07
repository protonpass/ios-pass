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

import Core
import SideMenuSwift
import SwiftUI
import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidSignOut()
}

final class HomeCoordinator: Coordinator {
    let sessionStorageProvider: SessionStorageProvider
    weak var delegate: HomeCoordinatorDelegate?

    private lazy var sideMenuController: SideMenuController = {
        let sideMenuController = SideMenuController(contentViewController: myVaultsNavigationController,
                                                    menuViewController: sidebarView)
        return sideMenuController
    }()

    private lazy var sidebarView: UIViewController = {
        let sidebarView = SidebarView(coordinator: self)
        return UIHostingController(rootView: sidebarView)
    }()

    private lazy var myVaultsNavigationController: UINavigationController = {
        let myVaultsView = MyVaultsView(coordinator: self)
        let myVaultsViewController = UIHostingController(rootView: myVaultsView)
        return UINavigationController(rootViewController: myVaultsViewController)
    }()

    private lazy var trashViewNavigationController: UIViewController = {
        let trashView = TrashView(coordinator: self)
        let trashViewController = UIHostingController(rootView: trashView)
        return UINavigationController(rootViewController: trashViewController)
    }()

    init(router: Router,
         navigationType: Coordinator.NavigationType,
         sessionStorageProvider: SessionStorageProvider) {
        self.sessionStorageProvider = sessionStorageProvider
        super.init(router: router, navigationType: navigationType)
        self.setUpSideMenuPreferences()
    }

    override var root: Presentable { sideMenuController }

    private func setUpSideMenuPreferences() {
        SideMenuController.preferences.basic.menuWidth = UIScreen.main.bounds.width * 4 / 5
        SideMenuController.preferences.basic.position = .sideBySide
        SideMenuController.preferences.basic.enablePanGesture = true
        SideMenuController.preferences.basic.enableRubberEffectWhenPanning = false
        SideMenuController.preferences.animation.shouldAddShadowWhenRevealing = true
        SideMenuController.preferences.animation.shadowColor = .black
        SideMenuController.preferences.animation.shadowAlpha = 0.52
        SideMenuController.preferences.animation.revealDuration = 0.25
        SideMenuController.preferences.animation.hideDuration = 0.25
    }

    func signOut() {
        delegate?.homeCoordinatorDidSignOut()
    }
}

// MARK: - Sidebar
extension HomeCoordinator {
    func showSidebar() {
        sideMenuController.revealMenu()
    }

    func handleSidebarItem(_ sidebarItem: SidebarItem) {
        switch sidebarItem {
        case .settings:
            break
        case .trash:
            sideMenuController.setContentViewController(to: trashViewNavigationController,
                                                        animated: true) { [unowned self] in
                self.sideMenuController.hideMenu()
            }
        case .help:
            break
        case .signOut:
            signOut()
        }
    }

    func showUserSwitcher() {
        print(#function)
    }
}

extension HomeCoordinator {
    /// For preview purposes
    static var preview: HomeCoordinator {
        .init(router: .init(),
              navigationType: .currentFlow,
              sessionStorageProvider: .preview)
    }
}
