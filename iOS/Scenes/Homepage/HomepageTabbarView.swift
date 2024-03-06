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

import Client
import Combine
import Core
import DesignSystem
import Factory
import ProtonCoreUIFoundations
import SwiftUI
import UIKit

enum HomepageTab: CaseIterable {
    case items, itemCreation, securityCenter, profile

    var index: Int {
        switch self {
        case .items:
            0
        case .itemCreation:
            1
        case .securityCenter:
            2
        case .profile:
            3
        }
    }

    var image: UIImage {
        switch self {
        case .items:
            IconProvider.listBullets
        case .itemCreation:
            IconProvider.plus
        case .securityCenter:
            IconProvider.shield
        case .profile:
            IconProvider.user
        }
    }

    var hint: String {
        switch self {
        case .items:
            "Homepage tab"
        case .itemCreation:
            "Create new item button"
        case .securityCenter:
            "Security centre tab"
        case .profile:
            "Profile tab"
        }
    }

    var identifier: String? {
        switch self {
        case .profile:
            "HomepageTabBarController_profileTabView"
        default:
            nil
        }
    }
}

@MainActor
protocol HomepageTabDelegate: AnyObject {
    func change(tab: HomepageTab)
    func refreshTabIcons()
    func hideTabbar(_ isHidden: Bool)
    func disableCreateButton(_ isDisabled: Bool)
}

struct HomepageTabbarView: UIViewControllerRepresentable {
    let itemsTabViewModel: ItemsTabViewModel
    let profileTabViewModel: ProfileTabViewModel
    let mainSecurityCenterViewModel: SecurityCenterViewModel
    weak var homepageCoordinator: HomepageCoordinator?
    weak var delegate: HomepageTabBarControllerDelegate?

    init(itemsTabViewModel: ItemsTabViewModel,
         profileTabViewModel: ProfileTabViewModel,
         mainSecurityCenterViewModel: SecurityCenterViewModel,
         homepageCoordinator: HomepageCoordinator? = nil,
         delegate: HomepageTabBarControllerDelegate? = nil) {
        self.itemsTabViewModel = itemsTabViewModel
        self.profileTabViewModel = profileTabViewModel
        self.homepageCoordinator = homepageCoordinator
        self.mainSecurityCenterViewModel = mainSecurityCenterViewModel
        self.delegate = delegate
    }

    func makeUIViewController(context: Context) -> HomepageTabBarController {
        let controller = HomepageTabBarController(itemsTabView: .init(viewModel: itemsTabViewModel),
                                                  profileTabView: .init(viewModel: profileTabViewModel),
                                                  securityCenter: .init(viewModel: mainSecurityCenterViewModel))
        controller.homepageTabBarControllerDelegate = delegate
        context.coordinator.homepageTabBarController = controller
        homepageCoordinator?.homepageTabDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: HomepageTabBarController, context: Context) {}

    func makeCoordinator() -> Coordinator { .init() }

    @MainActor
    final class Coordinator: NSObject, HomepageTabDelegate {
        var homepageTabBarController: HomepageTabBarController?

        func change(tab: HomepageTab) {
            homepageTabBarController?.select(tab: tab)
        }

        func refreshTabIcons() {
            homepageTabBarController?.refreshTabBarIcons()
        }

        func hideTabbar(_ isHidden: Bool) {
            homepageTabBarController?.hideTabBar(isHidden)
        }

        func disableCreateButton(_ isDisabled: Bool) {
            homepageTabBarController?.disableCreateButton(isDisabled)
        }
    }
}

@MainActor
protocol HomepageTabBarControllerDelegate: AnyObject {
    func selected(tab: HomepageTab)
}

final class HomepageTabBarController: UITabBarController, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let itemsTabView: ItemsTabView
    private let profileTabView: ProfileTabView
    private let mainSecurityCenterView: SecurityCenterView
    private var profileTabViewController: UIViewController?

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let logger = resolve(\SharedToolingContainer.logger)

    weak var homepageTabBarControllerDelegate: HomepageTabBarControllerDelegate?

    init(itemsTabView: ItemsTabView, profileTabView: ProfileTabView, securityCenter: SecurityCenterView) {
        self.itemsTabView = itemsTabView
        self.profileTabView = profileTabView
        mainSecurityCenterView = securityCenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        var controllers = [UIViewController]()
        let itemsTabViewController = UIHostingController(rootView: itemsTabView)
        itemsTabViewController.tabBarItem.image = HomepageTab.items.image
        itemsTabViewController.tabBarItem.accessibilityHint = HomepageTab.items.hint

        controllers.append(itemsTabViewController)

        let dummyViewController = UIViewController()
        dummyViewController.tabBarItem.image = HomepageTab.itemCreation.image
        dummyViewController.tabBarItem.accessibilityHint = HomepageTab.itemCreation.hint
        controllers.append(dummyViewController)

        let secureCenter = UIHostingController(rootView: mainSecurityCenterView)
        secureCenter.tabBarItem.image = HomepageTab.securityCenter.image
        secureCenter.tabBarItem.accessibilityHint = HomepageTab.securityCenter.hint
        controllers.append(secureCenter)

        let profileTabViewController = UIHostingController(rootView: profileTabView)
        profileTabViewController.tabBarItem.image = HomepageTab.profile.image
        profileTabViewController.tabBarItem.accessibilityHint = HomepageTab.profile.hint
        profileTabViewController.tabBarItem.accessibilityIdentifier = HomepageTab.profile.identifier
        self.profileTabViewController = profileTabViewController
        controllers.append(profileTabViewController)

        viewControllers =
            controllers // [itemsTabViewController, dummyViewController, secureCenter, profileTabViewController]

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .regular)
        tabBarAppearance.backgroundColor = PassColor.tabBarBackground
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = PassColor.textNorm
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = PassColor.interactionNormMajor2
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance

        if let tabBarItems = tabBar.items {
            for item in tabBarItems {
                item.title = nil
                item.imageInsets = .init(top: 8, left: 0, bottom: -8, right: 0)
            }
        }

        refreshTabBarIcons()
    }
}

// MARK: - Public APIs

extension HomepageTabBarController {
    func select(tab: HomepageTab) {
        selectedViewController = viewControllers?[tab.index]
    }

    func refreshTabBarIcons() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let plan = try await self.accessRepository.getPlan()

                let (image, selectedImage): (UIImage, UIImage) = switch plan.planType {
                case .free:
                    (IconProvider.user, IconProvider.user)
                case .business, .plus:
                    (PassIcon.tabProfilePaidUnselected, PassIcon.tabProfilePaidSelected)
                case .trial:
                    (PassIcon.tabProfileTrialUnselected, PassIcon.tabProfileTrialSelected)
                }

                profileTabViewController?.tabBarItem.image = image
                profileTabViewController?.tabBarItem.selectedImage = selectedImage
            } catch {
                logger.error(error)
            }
        }
    }

    func hideTabBar(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.7,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.7,
                       options: .curveEaseOut) { [weak self] in
            guard let self else { return }
            if isHidden {
                tabBar.frame.origin.y = view.frame.maxY + tabBar.frame.height
            } else {
                tabBar.frame.origin.y = view.frame.maxY - tabBar.frame.height
            }
            view.layoutIfNeeded()
        }
    }

    func disableCreateButton(_ isDisabled: Bool) {
        UIView.animate(withDuration: 0.5) { [weak self] in
            guard let self else { return }
            viewControllers?[HomepageTab.itemCreation.index].tabBarItem.isEnabled = !isDisabled
        }
    }
}

// MARK: - UITabBarControllerDelegate

extension HomepageTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        guard let viewControllers = tabBarController.viewControllers else { return false }
//        assert(viewControllers.count == 4)

        if viewController == viewControllers[HomepageTab.items.index] {
            homepageTabBarControllerDelegate?.selected(tab: HomepageTab.items)
            return true
        }

        if viewController == viewControllers[HomepageTab.itemCreation.index] {
            homepageTabBarControllerDelegate?.selected(tab: HomepageTab.itemCreation)
            return false
        }

        if viewController == viewControllers[HomepageTab.securityCenter.index] {
            homepageTabBarControllerDelegate?.selected(tab: HomepageTab.securityCenter)
            return true
        }

        if viewController == viewControllers[HomepageTab.profile.index] {
            homepageTabBarControllerDelegate?.selected(tab: HomepageTab.profile)
            return true
        }

        return false
    }
}
