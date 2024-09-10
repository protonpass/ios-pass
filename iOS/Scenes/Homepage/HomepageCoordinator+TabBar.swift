//
// HomepageCoordinator+TabBar.swift
// Proton Pass - Created on 29/02/2024.
// Copyright (c) 2024 Proton Technologies AG
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

// MARK: - HomepageTabBarControllerDelegate

import SwiftUI

extension HomepageCoordinator: HomepageTabBarControllerDelegate {
    func selected(tab: HomepageTab) {
        switch tab {
        case .items:
            itemsTab()
        case .authenticator:
            securityAuthenticator()
        case .itemCreation:
            createNewItem()
        case .passMonitor:
            passMonitor()
        case .profile:
            profileTab()
        }
    }
}

private extension HomepageCoordinator {
    func itemsTab() {
        if !isCollapsed() {
            let placeholderView = ItemDetailPlaceholderView { [weak self] in
                guard let self else { return }
                popTopViewController(animated: true)
            }
            push(placeholderView)
        }
    }

    func securityAuthenticator() {
        guard !isCollapsed() else {
            return
        }
        let view = AuthenticatorView()
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.large, parentViewController: rootViewController)
        present(viewController)
    }

    func createNewItem() {
        let viewModel = ItemTypeListViewModel { [weak self] type in
            guard let self else { return }
            dismissTopMostViewController { [weak self] in
                guard let self else { return }
                presentCreateItemView(for: type)
            }
        }
        let view = ItemTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        viewController.sheetPresentationController?.delegate = viewModel
        viewModel.uiSheetPresentationController = viewController.sheetPresentationController
        present(viewController)
    }

    func passMonitor() {
        guard !isCollapsed() else {
            return
        }
        let placeholderView = ItemDetailPlaceholderView { [weak self] in
            guard let self else { return }
            popTopViewController(animated: true)
        }
        push(placeholderView)
    }

    func profileTab() {
        if !isCollapsed() {
            showAccountMenu()
        }
    }
}
