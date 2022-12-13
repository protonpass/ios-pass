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

public protocol CoordinatorDelegate: AnyObject {
    func coordinatorWantsToToggleSidebar()
    func coordinatorWantsToShowLoadingHud()
    func coordinatorWantsToHideLoadingHud()
    func coordinatorWantsToAlertError(_ error: Error)
}

public protocol CoordinatorProtocol: AnyObject {
    var rootViewController: UIViewController { get }
    var coordinatorDelegate: CoordinatorDelegate? { get }

    func start<V: View>(with view: V)
    func start(with viewController: UIViewController)
    func push<V: View>(_ view: V, animated: Bool, hidesBackButton: Bool)
    func push(_ viewController: UIViewController, animated: Bool, hidesBackButton: Bool)
    func present<V: View>(_ view: V, animated: Bool, dismissible: Bool)
    func present(_ viewController: UIViewController, animated: Bool, dismissible: Bool)
    func dismissTopMostViewController(animated: Bool, completion: (() -> Void)?)
    func popToRoot(animated: Bool)
    func isAtRootViewController() -> Bool
}

public extension CoordinatorProtocol {
    func start<V: View>(with view: V) {
        start(with: UIHostingController(rootView: view))
    }

    func push<V: View>(_ view: V, animated: Bool, hidesBackButton: Bool) {
        push(UIHostingController(rootView: view), animated: animated, hidesBackButton: hidesBackButton)
    }

    func present<V: View>(_ view: V, animated: Bool, dismissible: Bool) {
        present(UIHostingController(rootView: view), animated: animated, dismissible: dismissible)
    }

    func present(_ viewController: UIViewController, animated: Bool, dismissible: Bool) {
        viewController.isModalInPresentation = !dismissible
        rootViewController.topMostViewController.present(viewController, animated: animated)
    }

    func dismissTopMostViewController(animated: Bool, completion: (() -> Void)?) {
        rootViewController.topMostViewController.dismiss(animated: animated, completion: completion)
    }
}

enum CoordinatorType {
    case navigation(UINavigationController)
    case split(UISplitViewController)

    var controller: UIViewController {
        switch self {
        case .navigation(let navigationController):
            return navigationController
        case .split(let splitViewController):
            return splitViewController
        }
    }
}

open class Coordinator2: CoordinatorProtocol {
    private let type: CoordinatorType

    public var rootViewController: UIViewController { type.controller }
    public weak var coordinatorDelegate: CoordinatorDelegate?
    private var topMostViewController: UIViewController? { rootViewController.topMostViewController }

    public init() {
        if UIDevice.current.isIpad {
            let splitViewController = UISplitViewController(style: .doubleColumn)
            splitViewController.preferredPrimaryColumnWidth = 450
            splitViewController.preferredDisplayMode = .oneBesideSecondary
            splitViewController.displayModeButtonVisibility = .never
            type = .split(splitViewController)
        } else {
            type = .navigation(PPNavigationController())
        }
    }

    public func start(with viewController: UIViewController) {
        switch type {
        case .navigation(let navigationController):
            navigationController.setViewControllers([viewController], animated: true)
        case .split(let splitViewController):
            splitViewController.setViewController(viewController, for: .primary)
        }
    }

    public func push(_ viewController: UIViewController, animated: Bool, hidesBackButton: Bool) {
        switch type {
        case .navigation(let navigationController):
            viewController.navigationItem.hidesBackButton = hidesBackButton
            if let topMostNavigationController = topMostViewController as? UINavigationController {
                topMostNavigationController.pushViewController(viewController, animated: animated)
            } else {
                navigationController.pushViewController(viewController, animated: animated)
            }
        case .split(let splitViewController):
            splitViewController.setViewController(viewController, for: .secondary)
        }
    }

    public func popToRoot(animated: Bool) {
        switch type {
        case .navigation(let navigationController):
            if let topMostNavigationController = topMostViewController as? UINavigationController {
                topMostNavigationController.popViewController(animated: animated)
            } else {
                navigationController.popViewController(animated: animated)
            }
        case .split:
            break
        }
    }

    public func isAtRootViewController() -> Bool {
        switch type {
        case .navigation(let navigationController):
            if let topMostNavigationController = topMostViewController as? UINavigationController {
                return topMostNavigationController.viewControllers.count == 1
            } else {
                return navigationController.viewControllers.count == 1
            }
        case .split:
            return true
        }
    }
}

open class Coordinator {
    private let navigationController: UINavigationController
    public var rootViewController: UIViewController { navigationController }
    public weak var coordinatorDelegate: CoordinatorDelegate?
    private var topMostViewController: UIViewController {
        navigationController.topMostViewController
    }

    public init() {
        self.navigationController = PPNavigationController()
    }

    public func start<V: View>(with view: V) {
        start(with: UIHostingController(rootView: view))
    }

    public func start(with viewController: UIViewController) {
        navigationController.setViewControllers([viewController], animated: true)
    }

    public func pushView<V: View>(_ view: V,
                                  animated: Bool = true,
                                  hidesBackButton: Bool = true) {
        let viewController = UIHostingController(rootView: view)
        pushViewController(viewController, animated: animated, hidesBackButton: hidesBackButton)
    }

    public func pushViewController(_ viewController: UIViewController,
                                   animated: Bool = true,
                                   hidesBackButton: Bool = true) {
        viewController.navigationItem.hidesBackButton = hidesBackButton
        if let presentedNavigationController =
            navigationController.presentedViewController as? UINavigationController {
            presentedNavigationController.pushViewController(viewController, animated: animated)
        } else {
            navigationController.pushViewController(viewController, animated: animated)
        }
    }

    public func presentView<V: View>(_ view: V,
                                     animated: Bool = true,
                                     dismissible: Bool = false) {
        presentViewController(UIHostingController(rootView: view),
                              animated: animated,
                              dismissible: dismissible)
    }

    public func presentViewFullScreen<V: View>(_ view: V,
                                               embedInNavigationController: Bool = false,
                                               modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
                                               animated: Bool = true) {
        let hostedViewController = UIHostingController(rootView: view)
        let viewController: UIViewController
        if embedInNavigationController {
            viewController = UINavigationController(rootViewController: hostedViewController)
        } else {
            viewController = hostedViewController
        }
        viewController.modalPresentationStyle = .fullScreen
        viewController.modalTransitionStyle = modalTransitionStyle
        presentViewController(viewController, animated: animated)
    }

    public func presentViewController(_ viewController: UIViewController,
                                      animated: Bool = true,
                                      dismissible: Bool = false) {
        viewController.isModalInPresentation = !dismissible
        topMostViewController.present(viewController, animated: animated)
    }

    public func presentViewControllerFullScreen(_ viewController: UIViewController,
                                                animated: Bool = true) {
        viewController.modalPresentationStyle = .fullScreen
        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.present(viewController, animated: animated)
        } else {
            navigationController.present(viewController, animated: animated)
        }
    }

    public func dismissTopMostViewController(animated: Bool = true,
                                             completion: (() -> Void)? = nil) {
        topMostViewController.dismiss(animated: animated, completion: completion)
    }

    public func popToRoot(animated: Bool = true) {
        if let topMostNavigationController = topMostViewController as? UINavigationController {
            topMostNavigationController.popToRootViewController(animated: animated)
        } else {
            navigationController.popToRootViewController(animated: animated)
        }
    }

    public func isAtRootViewController() -> Bool {
        if let presentedNavigationController =
            navigationController.presentedViewController as? UINavigationController {
            return presentedNavigationController.viewControllers.count == 1
        } else {
            return navigationController.viewControllers.count == 1
        }
    }
}

public extension Coordinator {
    func toggleSidebar() { coordinatorDelegate?.coordinatorWantsToToggleSidebar() }

    func showLoadingHud() { coordinatorDelegate?.coordinatorWantsToShowLoadingHud() }

    func hideLoadingHud() { coordinatorDelegate?.coordinatorWantsToHideLoadingHud() }

    func alertError(_ error: Error) { coordinatorDelegate?.coordinatorWantsToAlertError(error) }
}

public extension Coordinator2 {
    func toggleSidebar() { coordinatorDelegate?.coordinatorWantsToToggleSidebar() }
    func showLoadingHud() { coordinatorDelegate?.coordinatorWantsToShowLoadingHud() }
    func hideLoadingHud() { coordinatorDelegate?.coordinatorWantsToHideLoadingHud() }
    func alertError(_ error: Error) { coordinatorDelegate?.coordinatorWantsToAlertError(error) }
}

private final class PPNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
