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
import DesignSystem
import SwiftUI
import UIKit

@MainActor
public protocol CoordinatorProtocol: AnyObject {
    var rootViewController: UIViewController { get }

    func start<PrimaryView: View, SecondaryView: View>(with view: PrimaryView,
                                                       secondaryView: SecondaryView)
    func start(with viewController: UIViewController, secondaryViewController: UIViewController?)
    func push<V: View>(_ view: V, animated: Bool, hidesBackButton: Bool)
    func push(_ viewController: UIViewController, animated: Bool, hidesBackButton: Bool)
    func present(_ viewController: UIViewController,
                 animated: Bool,
                 dismissible: Bool,
                 delay: TimeInterval,
                 uniquenessTag: (any RawRepresentable<Int>)?)
    func dismissTopMostViewController(animated: Bool, completion: (() -> Void)?)
    func dismissAllViewControllers(animated: Bool, completion: (() -> Void)?)
    func coordinatorDidDismiss()
    func updateFloatingView(floatingView: UIView?, shouldAdd: Bool)
}

public extension CoordinatorProtocol {
    func start(with view: some View,
               secondaryView: some View) {
        start(with: UIHostingController(rootView: view),
              secondaryViewController: UIHostingController(rootView: secondaryView))
    }

    func push(_ view: some View, animated: Bool = true, hidesBackButton: Bool = true) {
        push(UIHostingController(rootView: view), animated: animated, hidesBackButton: hidesBackButton)
    }

    /// When `uniquenessTag` is set and there is a sheet that holds the same tag,
    /// we dismiss the top most sheet and do nothing. Otherwise we present the sheet as normal
    func present(_ viewController: UIViewController,
                 animated: Bool = true,
                 dismissible: Bool = true,
                 delay: TimeInterval = 0.1,
                 uniquenessTag: (any RawRepresentable<Int>)? = nil) {
        viewController.sheetPresentationController?.preferredCornerRadius = 16
        viewController.isModalInPresentation = !dismissible
        if let uniquenessTag {
            viewController.view.tag = uniquenessTag.rawValue
            if rootViewController.containsUniqueSheet(uniquenessTag) {
                rootViewController.topMostViewController.dismiss(animated: animated)
                return
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else {
                return
            }
            rootViewController.topMostViewController.present(viewController, animated: true)
        }
    }

    func dismissTopMostViewController(animated: Bool = true, completion: (() -> Void)? = nil) {
        rootViewController.topMostViewController.dismiss(animated: animated) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                completion?()
                guard let self else { return }
                coordinatorDidDismiss()
            }
        }
    }

    func dismissAllViewControllers(animated: Bool = true, completion: (() -> Void)? = nil) {
        rootViewController.dismiss(animated: animated) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                completion?()
                guard let self else { return }
                coordinatorDidDismiss()
            }
        }
    }

    func coordinatorDidDismiss() {}

    func updateFloatingView(floatingView: UIView?, shouldAdd: Bool) {
        let viewTag = 1
        // Locate the UITabBarController in the view hierarchy
        if let tabBarController = findTabBarController(in: rootViewController), let floatingView {
            if shouldAdd {
                if tabBarController.view.viewWithTag(viewTag) == nil {
                    floatingView.tag = viewTag
                    floatingView.backgroundColor = UIColor.clear
                    // Check if the floating view is already added
                    if floatingView.superview == nil {
                        // Customize the floating view's appearance and position above the tab bar
                        floatingView.translatesAutoresizingMaskIntoConstraints = false
                        tabBarController.view.addSubview(floatingView)

                        // Position the floating view above the tab bar
                        NSLayoutConstraint.activate([
                            floatingView.centerXAnchor.constraint(equalTo: tabBarController.view.centerXAnchor),
                            floatingView.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor,
                                                                 constant: -10),
                            floatingView.leadingAnchor
                                .constraint(equalTo: tabBarController.view.leadingAnchor,
                                            constant: 16),
                            floatingView.trailingAnchor
                                .constraint(equalTo: tabBarController.view.trailingAnchor,
                                            constant: -16)
                        ])
                    }
                }
            } else {
                if let floatingView = tabBarController.view.viewWithTag(viewTag) {
                    // Remove the floating view if present
                    floatingView.removeFromSuperview()
                }
            }
        } else {
            if !shouldAdd {
                if let floatingView = rootViewController.view.window?.viewWithTag(viewTag) {
                    floatingView.removeFromSuperview()
                }
            }
        }
    }

    // Helper function to recursively search for UITabBarController
    func findTabBarController(in viewController: UIViewController) -> UITabBarController? {
        // Check if the current view controller is a UITabBarController
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }

        // Search in the children of the current view controller
        for child in viewController.children {
            if let found = findTabBarController(in: child) {
                return found
            }
        }

        // If presented, search in the presented view controller
        if let presented = viewController.presentedViewController {
            return findTabBarController(in: presented)
        }

        // Return nil if no UITabBarController is found in this branch
        return nil
    }
}

enum CoordinatorType {
    case navigation(PPNavigationController)
    case split(PPSplitViewController)

    var controller: UIViewController {
        switch self {
        case let .navigation(navigationController):
            navigationController
        case let .split(splitViewController):
            splitViewController
        }
    }
}

@MainActor
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

    public func start(with viewController: UIViewController, secondaryViewController: UIViewController?) {
        switch type {
        case let .navigation(navigationController):
            navigationController.setViewControllers([viewController], animated: true)
        case let .split(splitViewController):
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
            case let .navigation(navigationController):
                navigationController.pushViewController(viewController, animated: animated)
            case let .split(splitViewController):
                /// Embed in a `UINavigationController` so that `splitViewController` replaces the secondary view
                /// instead of pushing it into the navigation stack of the current secondary view controller.
                /// This is to reduce memory footprint.
                let navigationController = UINavigationController(rootViewController: viewController)
                navigationController.isNavigationBarHidden = true

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
            case let .navigation(navigationController):
                navigationController.popViewController(animated: animated)
            case let .split(splitViewController):
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

    /// Only applicable for iPad
    /// `true` when the app is not in full screen (only show 1 page at a time, not in split mode)
    public func isCollapsed() -> Bool {
        switch type {
        case .navigation:
            true
        case let .split(splitViewController):
            splitViewController.isCollapsed
        }
    }
}

final class PPNavigationController: UINavigationController, UIGestureRecognizerDelegate {
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
}

final class PPSplitViewController: UISplitViewController {
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
}
