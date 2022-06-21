//
// Router.swift
// Proton Key - Created on 20/06/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import Foundation
import UIKit

public class Router: NSObject {
    private var completions: [UIViewController: () -> Void]
    private let navigationController: UINavigationController

    deinit {
        if let presented = navigationController.presentedViewController {
            dismiss(presented)
        }
    }

    public init(navigationController: UINavigationController = UINavigationController()) {
        self.navigationController = navigationController
        self.completions = [:]
        super.init()
        self.navigationController.delegate = self
    }

    public func present(_ presentable: Presentable, animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.present(presentable.toPresentable(), animated: animated, completion: completion)
    }

    public func dismiss(_ presentable: Presentable, animated: Bool = true, completion: (() -> Void)? = nil) {
        if navigationController.presentedViewController == presentable.toPresentable() {
            navigationController.dismiss(animated: animated, completion: completion)
        }
    }

    public func dismiss(coordinator: Coordinator, animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(coordinator.toPresentable())
    }

    public func push(_ presentable: Presentable, animated: Bool = true, completion: (() -> Void)? = nil) {
        let controller = presentable.toPresentable()

        // Never push an UINavigationController
        if controller is UINavigationController { return }

        if let completion = completion {
            completions[controller] = completion
        }

        navigationController.pushViewController(controller, animated: animated)
    }

    public func pop(animated: Bool = true) {
        if let controller = navigationController.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }

    public func setRoot(_ presentable: Presentable, hideBar: Bool = false, completion: (() -> Void)? = nil) {
        // Call all completions so all coordinators can be deallocated
        for controller in navigationController.viewControllers {
            runCompletion(for: controller)
        }

        let controller = presentable.toPresentable()

        if let vc = controller as? UINavigationController {
            navigationController.setViewControllers(vc.viewControllers, animated: false)
            if let completion = completion {
                vc.viewControllers.forEach { completions[$0] = completion }
            }
        } else {
            navigationController.setViewControllers([controller], animated: false)
            if let completion = completion {
                completions[controller] = completion
            }
        }
        navigationController.isNavigationBarHidden = hideBar
    }

    // MARK: - Pop ViewControllers
    public func popToRoot(animated: Bool = true) {
        if let controllers = navigationController.popToRootViewController(animated: animated) {
            controllers.forEach { runCompletion(for: $0) }
        }
    }

    public func popTo(_ presentable: Presentable, animated: Bool = true) {
        if let controllers = navigationController.popToViewController(presentable.toPresentable(),
                                                                      animated: animated) {
            controllers.forEach { runCompletion(for: $0) }
        }
    }

    // MARK: - Completion on ViewController
    private func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else { return }
        completion()
        completions.removeValue(forKey: controller)
    }
}

extension Router: Presentable {
    public func toPresentable() -> UIViewController { navigationController }
}

extension Router: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        // Ensure the view controller is popping
        guard let poppedViewController = navigationController.transitionCoordinator?.viewController(forKey: .from),
              !navigationController.viewControllers.contains(poppedViewController) else {
            return
        }

        runCompletion(for: poppedViewController)
    }
}
