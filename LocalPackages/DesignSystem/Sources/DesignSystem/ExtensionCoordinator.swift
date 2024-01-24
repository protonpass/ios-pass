//
// ExtensionCoordinator.swift
// Proton Pass - Created on 22/01/2024.
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
//

import Macro
import MBProgressHUD
import SwiftUI

@MainActor
public protocol ExtensionCoordinator: AnyObject {
    func getRootViewController() -> UIViewController?
    func getLastChildViewController() -> UIViewController?
    func setLastChildViewController(_ viewController: UIViewController)
    func showView(_ view: some View)
    func alert(error: Error, onCancel: @escaping () -> Void)
    func showLoadingHud()
    func hideLoadingHud()
}

public extension ExtensionCoordinator {
    func showView(_ view: some View) {
        guard let rootViewController = getRootViewController() else {
            assertionFailure("rootViewController is not set")
            return
        }
        if let lastChildViewController = getLastChildViewController() {
            lastChildViewController.willMove(toParent: nil)
            lastChildViewController.view.removeFromSuperview()
            lastChildViewController.removeFromParent()
        }

        let viewController = UIHostingController(rootView: view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        rootViewController.view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: rootViewController.view.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor)
        ])
        rootViewController.addChild(viewController)
        viewController.didMove(toParent: rootViewController)
        setLastChildViewController(viewController)
    }

    #warning("Localize Design System package")
    func alert(error: Error, onCancel: @escaping () -> Void) {
        let alert = UIAlertController(title: #localized("Error occured"),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: #localized("Cancel"), style: .cancel) { _ in
            onCancel()
        }
        alert.addAction(cancelAction)
        getRootViewController()?.present(alert, animated: true)
    }

    func showLoadingHud() {
        guard let topMostViewController = getRootViewController()?.topMostViewController else {
            return
        }
        MBProgressHUD.showAdded(to: topMostViewController.view, animated: true)
    }

    func hideLoadingHud() {
        guard let topMostViewController = getRootViewController()?.topMostViewController else {
            return
        }
        MBProgressHUD.hide(for: topMostViewController.view, animated: true)
    }
}
