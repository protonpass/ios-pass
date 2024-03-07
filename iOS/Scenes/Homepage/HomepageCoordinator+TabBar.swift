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
        case .itemCreation:
            createNewItem()
        case .securityCenter:
            securityCenter()
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

    func createNewItem() {
        let viewModel = ItemTypeListViewModel()
        viewModel.delegate = self
        let view = ItemTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.setDetentType(.medium, parentViewController: rootViewController)
        present(viewController)
    }

    func securityCenter() {
        guard !isCollapsed() else {
            return
        }
        let placeholderView = ItemDetailPlaceholderView { [weak self] in
            guard let self else { return }
            popTopViewController(animated: true)
        }
        push(placeholderView)
//        let asSheet = shouldShowAsSheet()
//        let view = SecurityCenterView(viewModel: SecurityCenterViewModel())
//        showView(view: view, asSheet: asSheet)
    }

    func profileTab() {
        if !isCollapsed() {
            profileTabViewModelWantsToShowAccountMenu()
        }
    }
}
