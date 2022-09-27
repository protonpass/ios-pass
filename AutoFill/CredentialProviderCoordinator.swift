//
// CredentialProviderCoordinator.swift
// Proton Pass - Created on 27/09/2022.
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

import AuthenticationServices
import Core
import CryptoKit
import SwiftUI

public final class CredentialProviderCoordinator {
    private let context: ASCredentialProviderExtensionContext
    private let rootViewController: UIViewController
    private var lastChildViewController: UIViewController?

    init(context: ASCredentialProviderExtensionContext,
         rootViewController: UIViewController) {
        self.context = context
        self.rootViewController = rootViewController
    }

    func start(sessionData: SessionData?, symmetricKey: String?) {
        guard let sessionData = sessionData,
              let symmetricKey = symmetricKey,
              let symmetricKeyData = symmetricKey.data(using: .utf8) else {
            showNoLoggedInView()
            return
        }

        showCredentialsView(sessionData: sessionData,
                            symmetricKey: .init(data: symmetricKeyData))
    }
}

// MARK: - Context actions
extension CredentialProviderCoordinator {
    func cancel(errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain, code: errorCode.rawValue)
        context.cancelRequest(withError: error)
    }

    func complete(with credential: ASPasswordCredential) {
        context.completeRequest(withSelectedCredential: credential, completionHandler: nil)
    }
}

// MARK: - Views
extension CredentialProviderCoordinator {
    /// From Swift 5.7 this can be rewritten as `func showView(_ view: some View)`
    private func showView<V: View>(_ view: V) {
        if let lastChildViewController = lastChildViewController {
            lastChildViewController.willMove(toParent: nil)
            lastChildViewController.view.removeFromSuperview()
            lastChildViewController.removeFromParent()
        }

        let viewController = UIHostingController(rootView: view)
        rootViewController.addChild(viewController)
        viewController.view.frame = rootViewController.view.frame
        rootViewController.view.addSubview(viewController.view)
        viewController.didMove(toParent: rootViewController)
        lastChildViewController = viewController
    }

    private func showCredentialsView(sessionData: SessionData,
                                     symmetricKey: SymmetricKey) {
        let viewModel = CredentialsViewModel(symmetricKey: symmetricKey)
        viewModel.onClose = { [unowned self] in
            self.cancel(errorCode: .userCanceled)
        }
        viewModel.onSelect = { [unowned self] in
            let credential = ASPasswordCredential(user: "john@example.com",
                                                  password: "password")
            self.complete(with: credential)
        }
        showView(CredentialsView(viewModel: viewModel))
    }

    private func showNoLoggedInView() {
        let view = NotLoggedInView { [unowned self] in
            self.cancel(errorCode: .userCanceled)
        }
        showView(view)
    }
}
