//
// Coordinator.swift
// Proton Pass - Created on 20/06/2022.
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

import Combine
import SwiftUI
import UIComponents
import UIKit

public protocol CoordinatorProtocol: AnyObject {
    var rootViewController: UIViewController { get }

    func start<PrimaryView: View, SecondaryView: View>(with view: PrimaryView,
                                                       secondaryView: SecondaryView)
    func start(with viewController: UIViewController, secondaryViewController: UIViewController?)
    func push<V: View>(_ view: V, animated: Bool, hidesBackButton: Bool)
    func push(_ viewController: UIViewController, animated: Bool, hidesBackButton: Bool)
    func present<V: View>(_ view: V,
                          userInterfaceStyle: UIUserInterfaceStyle,
                          animated: Bool,
                          dismissible: Bool)
    func present(_ viewController: UIViewController,
                 userInterfaceStyle: UIUserInterfaceStyle,
                 animated: Bool,
                 dismissible: Bool)
    func dismissTopMostViewController(animated: Bool, completion: (() -> Void)?)
    func popTopViewController(animated: Bool)
    func popToRoot(animated: Bool, secondaryViewController: UIViewController?)
    func isAtRootViewController() -> Bool
    func setStatusBarStyle(_ style: UIStatusBarStyle)
}

public extension CoordinatorProtocol {
    func start<PrimaryView: View, SecondaryView: View>(with view: PrimaryView,
                                                       secondaryView: SecondaryView) {
        start(with: UIHostingController(rootView: view),
              secondaryViewController: UIHostingController(rootView: secondaryView))
    }

    func push<V: View>(_ view: V, animated: Bool = true, hidesBackButton: Bool = true) {
        push(UIHostingController(rootView: view), animated: animated, hidesBackButton: hidesBackButton)
    }

    func present<V: View>(_ view: V,
                          userInterfaceStyle: UIUserInterfaceStyle,
                          animated: Bool = true,
                          dismissible: Bool = true) {
        present(UIHostingController(rootView: view),
                userInterfaceStyle: userInterfaceStyle,
                animated: animated,
                dismissible: dismissible)
    }

    func present(_ viewController: UIViewController,
                 userInterfaceStyle: UIUserInterfaceStyle,
                 animated: Bool = true,
                 dismissible: Bool = true) {
        viewController.sheetPresentationController?.preferredCornerRadius = 16
        viewController.isModalInPresentation = !dismissible
        viewController.overrideUserInterfaceStyle = userInterfaceStyle
        rootViewController.topMostViewController.present(viewController, animated: animated)
    }

    func dismissTopMostViewController(animated: Bool = true, completion: (() -> Void)? = nil) {
        rootViewController.topMostViewController.dismiss(animated: animated, completion: completion)
    }
}

enum CoordinatorType {
    case navigation(PPNavigationController)
    case split(PPSplitViewController)

    var controller: UIViewController {
        switch self {
        case .navigation(let navigationController):
            return navigationController
        case .split(let splitViewController):
            return splitViewController
        }
    }
}

open class Coordinator: CoordinatorProtocol {
    private let type: CoordinatorType

    public var rootViewController: UIViewController { type.controller }
    public var topMostViewController: UIViewController { rootViewController.topMostViewController }

    public init() {
        if UIDevice.current.isIpad {
            let splitViewController = PPSplitViewController(style: .doubleColumn)
            splitViewController.maximumPrimaryColumnWidth = 450
            splitViewController.minimumPrimaryColumnWidth = 400
            splitViewController.preferredPrimaryColumnWidthFraction = 0.4
            splitViewController.preferredDisplayMode = .oneBesideSecondary
            splitViewController.preferredSplitBehavior = .tile
            splitViewController.displayModeButtonVisibility = .never
            type = .split(splitViewController)
        } else {
            type = .navigation(PPNavigationController())
        }
    }

    public func setStatusBarStyle(_ style: UIStatusBarStyle) {
        switch type {
        case .navigation(let navigationController):
            navigationController.setStatusBarStyle(style)
        case .split(let splitViewController):
            splitViewController.setStatusBarStyle(style)
        }
    }

    public func start(with viewController: UIViewController, secondaryViewController: UIViewController?) {
        switch type {
        case .navigation(let navigationController):
            navigationController.setViewControllers([viewController], animated: true)
        case .split(let splitViewController):
            splitViewController.setViewController(viewController, for: .primary)
            if let secondaryViewController {
                splitViewController.setViewController(secondaryViewController, for: .secondary)
            }
        }
    }

    public func push(_ viewController: UIViewController, animated: Bool, hidesBackButton: Bool) {
        viewController.navigationItem.hidesBackButton = hidesBackButton
        if let topMostNavigationController = topMostViewController as? UINavigationController {
            topMostNavigationController.pushViewController(viewController, animated: true)
        } else {
            switch type {
            case .navigation(let navigationController):
                navigationController.pushViewController(viewController, animated: animated)
            case .split(let splitViewController):
                /// Embed in a `UINavigationController` so that `splitViewController` replaces the secondary view
                /// instead of pushing it into the navigation stack of the current secondary view controller.
                /// This is to reduce memory footprint.
                let navigationController = UINavigationController(rootViewController: viewController)
                splitViewController.setViewController(navigationController, for: .secondary)
                splitViewController.show(.secondary)
            }
        }
    }

    public func popTopViewController(animated: Bool = true) {
        if let topMostNavigationController = topMostViewController as? UINavigationController {
            topMostNavigationController.popViewController(animated: animated)
        } else {
            switch type {
            case .navigation(let navigationController):
                navigationController.popViewController(animated: animated)
            case .split(let splitViewController):
                /// Show primary view controller if it's hidden
                /// Hide primary view controller if it's visible
                switch splitViewController.displayMode {
                case .secondaryOnly:
                    splitViewController.show(.primary)
                case .oneBesideSecondary, .oneOverSecondary:
                    if splitViewController.isCollapsed {
                        splitViewController.show(.primary)
                    } else {
                        splitViewController.hide(.primary)
                    }
                default:
                    break
                }
            }
        }
    }

    public func popToRoot(animated: Bool, secondaryViewController: UIViewController?) {
        if let topMostNavigationController = topMostViewController as? UINavigationController {
            topMostNavigationController.popToRootViewController(animated: animated)
        } else {
            switch type {
            case .navigation(let navigationController):
                navigationController.popToRootViewController(animated: animated)
            case .split(let splitViewController):
                splitViewController.show(.primary)
                if let secondaryViewController {
                    secondaryViewController.navigationItem.hidesBackButton = true
                    let navigationController = UINavigationController(rootViewController: secondaryViewController)
                    // Set to nil before setting to the real secondary view controller
                    // otherwise in spit mode, secondary view is shown instead of primary one.
                    splitViewController.setViewController(nil, for: .secondary)
                    splitViewController.setViewController(navigationController, for: .secondary)
                }
            }
        }
    }

    public func isAtRootViewController() -> Bool {
        if topMostViewController == rootViewController {
            switch type {
            case .navigation(let navigationController):
                return navigationController.viewControllers.count == 1
            case .split:
                return true
            }
        } else if let topMostNavigationController = topMostViewController as? UINavigationController {
            return topMostNavigationController.viewControllers.count == 1
        }
        return false
    }
}

public final class PPNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    private var statusBarStyle = UIStatusBarStyle.default

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = true
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }

    func setStatusBarStyle(_ style: UIStatusBarStyle) {
        statusBarStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
}

public final class PPSplitViewController: UISplitViewController {
    private var statusBarStyle = UIStatusBarStyle.default

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        show(.primary)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        show(.primary)
    }

    func setStatusBarStyle(_ style: UIStatusBarStyle) {
        statusBarStyle = style
        setNeedsStatusBarAppearanceUpdate()
    }
}
