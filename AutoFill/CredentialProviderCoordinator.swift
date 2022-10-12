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
import Crypto
import CryptoKit
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import SwiftUI

public final class CredentialProviderCoordinator {
    @KeychainStorage(key: .sessionData)
    private var sessionData: SessionData?

    @KeychainStorage(key: .symmetricKey)
    private var symmetricKey: String?

    private let keychain: Keychain
    private let keymaker: Keymaker
    private var apiService: APIService
    private let container: NSPersistentContainer
    private let context: ASCredentialProviderExtensionContext
    private let credentialManager: CredentialManagerProtocol
    private let rootViewController: UIViewController
    private var lastChildViewController: UIViewController?

    init(apiService: APIService,
         container: NSPersistentContainer,
         context: ASCredentialProviderExtensionContext,
         credentialManager: CredentialManagerProtocol,
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
        self.credentialManager = credentialManager
        self.rootViewController = rootViewController
        self.apiService.authDelegate = self
        self.apiService.serviceDelegate = self
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let sessionData = sessionData,
              let symmetricKeyData = symmetricKey?.data(using: .utf8) else {
            showNoLoggedInView()
            return
        }

        showCredentialsView(userData: sessionData.userData,
                            symmetricKey: .init(data: symmetricKeyData),
                            serviceIdentifiers: serviceIdentifiers)
    }

    /// QuickType bar support
    func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let sessionData = sessionData,
              let symmetricKeyData = symmetricKey?.data(using: .utf8),
              let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancel(errorCode: .failed)
            return
        }

        let databaseIsUnlocked = true
        if databaseIsUnlocked {
            let symmetricKey = SymmetricKey(data: symmetricKeyData)
            let itemRepository = ItemRepository(userData: sessionData.userData,
                                                symmetricKey: symmetricKey,
                                                container: container,
                                                apiService: apiService)
            Task { @MainActor in
                do {
                    let ids = try AutoFillCredential.IDs.deserializeBase64(recordIdentifier)
                    if let encryptedItem = try await itemRepository.getItem(shareId: ids.shareId,
                                                                            itemId: ids.itemId) {
                        let decryptedItem = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
                        if case let .login(username, password, _) = decryptedItem.contentData {
                            complete(credential: .init(user: username, password: password),
                                     encryptedItem: encryptedItem,
                                     itemRepository: itemRepository,
                                     symmetricKey: symmetricKey,
                                     serviceIdentifiers: [credentialIdentity.serviceIdentifier])
                        }
                    } else {
                        cancel(errorCode: .failed)
                    }
                } catch {
                    cancel(errorCode: .failed)
                }
            }
        } else {
            cancel(errorCode: .userInteractionRequired)
        }
    }
}

// MARK: - AuthDelegate
extension CredentialProviderCoordinator: AuthDelegate {
    public func onUpdate(credential: Credential, sessionUID: String) {}

    public func onRefresh(sessionUID: String,
                          service: APIService,
                          complete: @escaping AuthRefreshResultCompletion) {}

    public func authCredential(sessionUID: String) -> AuthCredential? {
        sessionData?.userData.credential
    }

    public func credential(sessionUID: String) -> Credential? { nil }

    public func onLogout(sessionUID: String) {}
}

// MARK: - APIServiceDelegate
extension CredentialProviderCoordinator: APIServiceDelegate {
    public var appVersion: String { "iOSPass_\(Bundle.main.versionNumber)" }
    public var userAgent: String? { UserAgent.default.ua }
    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var additionalHeaders: [String: String]? { nil }

    public func onDohTroubleshot() {}

    public func onUpdate(serverTime: Int64) {
        CryptoUpdateTime(serverTime)
    }

    public func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        return true
    }

    private func updateRank(encryptedItem: SymmetricallyEncryptedItem,
                            symmetricKey: SymmetricKey,
                            serviceIdentifiers: [ASCredentialServiceIdentifier]) async throws {
        let matcher = URLUtils.Matcher.default
        let decryptedItem = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
        if case let .login(email, _, urls) = decryptedItem.contentData {
            let serviceUrls = serviceIdentifiers
                .map { $0.identifier }
                .compactMap { URL(string: $0) }
            let itemUrls = urls.compactMap { URL(string: $0) }
            let matchedUrls = itemUrls.filter { itemUrl in
                serviceUrls.contains { serviceUrl in
                    matcher.isMatched(itemUrl, serviceUrl)
                }
            }

            let credentials = matchedUrls
                .map { AutoFillCredential(shareId: encryptedItem.shareId,
                                          itemId: encryptedItem.item.itemID,
                                          username: email,
                                          url: $0.absoluteString,
                                          lastUsedTime: Int64(Date().timeIntervalSince1970)) }
            try await credentialManager.insert(credentials: credentials)
        }
    }
}

// MARK: - Context actions
extension CredentialProviderCoordinator {
    func cancel(errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain, code: errorCode.rawValue)
        context.cancelRequest(withError: error)
    }

    func complete(credential: ASPasswordCredential,
                  encryptedItem: SymmetricallyEncryptedItem,
                  itemRepository: ItemRepositoryProtocol,
                  symmetricKey: SymmetricKey,
                  serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        Task {
            do {
                try await updateRank(encryptedItem: encryptedItem,
                                     symmetricKey: symmetricKey,
                                     serviceIdentifiers: serviceIdentifiers)
                try await itemRepository.update(item: encryptedItem,
                                                lastUsedTime: Date().timeIntervalSince1970)
                context.completeRequest(withSelectedCredential: credential, completionHandler: nil)
            } catch {
                PPLogger.shared?.log(error)
            }
        }
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
        viewModel.onSelect = { [unowned self] credential, item in
            self.complete(credential: credential,
                          encryptedItem: item,
                          itemRepository: itemRepository,
                          symmetricKey: symmetricKey,
                          serviceIdentifiers: serviceIdentifiers)
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
