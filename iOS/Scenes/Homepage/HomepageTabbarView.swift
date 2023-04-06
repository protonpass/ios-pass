//
// HomepageTabbarView.swift
// Proton Pass - Created on 03/04/2023.
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

import Core
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents
import UIKit

struct HomepageTabbarView: UIViewControllerRepresentable {
    let itemsTabViewModel: ItemsTabViewModel
    let profileTabViewModel: ProfileTabViewModel
    weak var delegate: HomepageTabBarControllerDelegate?

    func makeUIViewController(context: Context) -> HomepageTabBarController {
        let controller = HomepageTabBarController(itemsTabView: .init(viewModel: itemsTabViewModel),
                                                  profileTabView: .init(viewModel: profileTabViewModel))
        controller.homepageTabBarControllerDelegate = delegate
        return controller
    }

    func updateUIViewController(_ uiViewController: HomepageTabBarController, context: Context) {}
}

private final class DummyViewController: UIViewController {}

protocol HomepageTabBarControllerDelegate: AnyObject {
    func homepageTabBarControllerWantToCreateNewItem()
}

final class HomepageTabBarController: UITabBarController, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let itemsTabView: ItemsTabView
    private let profileTabView: ProfileTabView
    private let dummyViewController = DummyViewController()

    weak var homepageTabBarControllerDelegate: HomepageTabBarControllerDelegate?

    init(itemsTabView: ItemsTabView, profileTabView: ProfileTabView) {
        self.itemsTabView = itemsTabView
        self.profileTabView = profileTabView
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        let itemsTabViewController = UIHostingController(rootView: itemsTabView)
        itemsTabViewController.tabBarItem.image = IconProvider.listBullets

        let profileTabViewController = UIHostingController(rootView: profileTabView)
        profileTabViewController.tabBarItem.image = IconProvider.user

        dummyViewController.tabBarItem.image = IconProvider.plus

        viewControllers = [itemsTabViewController, dummyViewController, profileTabViewController]

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        tabBarAppearance.backgroundColor = PassColor.tabBarBackground
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = PassColor.textNorm
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = PassColor.interactionNormMajor2
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance

        if let taBarItems = tabBar.items {
            for item in taBarItems {
                item.title = nil
                item.imageInsets = .init(top: 8, left: 0, bottom: -8, right: 0)
            }
        }
    }
}

extension HomepageTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if viewController.isKind(of: DummyViewController.self) {
            homepageTabBarControllerDelegate?.homepageTabBarControllerWantToCreateNewItem()
            return false
        }
        return true
    }
}
