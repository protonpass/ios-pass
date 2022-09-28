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
import Client
import Core
import CoreData
import CryptoKit
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Services
import SwiftUI

public final class CredentialProviderCoordinator {
    @KeychainStorage(key: .sessionData)
    private var sessionData: SessionData?

    @KeychainStorage(key: .symmetricKey)
    private var symmetricKey: String?

    private let keychain: Keychain
    private let keymaker: Keymaker
    private let apiService: APIService
    private let container: NSPersistentContainer
    private let context: ASCredentialProviderExtensionContext
    private let rootViewController: UIViewController
    private var lastChildViewController: UIViewController?

    init(apiService: APIService,
         container: NSPersistentContainer,
         context: ASCredentialProviderExtensionContext,
         rootViewController: UIViewController) {
        let keychain = PPKeychain()
        self.keychain = keychain
        self.keymaker = .init(autolocker: Autolocker(lockTimeProvider: keychain),
                              keychain: keychain)
        self._sessionData.setKeychain(keychain)
        self._sessionData.setMainKeyProvider(keymaker)
        self._symmetricKey.setKeychain(keychain)
        self._symmetricKey.setMainKeyProvider(keymaker)
        self.apiService = apiService
        self.container = container
        self.context = context
        self.rootViewController = rootViewController
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let sessionData = sessionData,
              let symmetricKey = symmetricKey,
              let symmetricKeyData = symmetricKey.data(using: .utf8) else {
            showNoLoggedInView()
            return
        }

        showCredentialsView(userData: sessionData.userData,
                            symmetricKey: .init(data: symmetricKeyData),
                            serviceIdentifiers: serviceIdentifiers)
    }

    /// QuickType bar support
    func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        let databaseIsUnlocked = true
        if databaseIsUnlocked {
            print(credentialIdentity)
        } else {
            cancel(errorCode: .userInteractionRequired)
        }
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

    private func showCredentialsView(userData: UserData,
                                     symmetricKey: SymmetricKey,
                                     serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let itemRepository = ItemRepository(userData: userData,
                                            symmetricKey: symmetricKey,
                                            container: container,
                                            apiService: apiService)
        let viewModel = CredentialsViewModel(itemRepository: itemRepository,
                                             symmetricKey: symmetricKey,
                                             serviceIdentifiers: serviceIdentifiers)
        viewModel.onClose = { [unowned self] in
            self.cancel(errorCode: .userCanceled)
        }
        viewModel.onSelect = { [unowned self] credential in
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
