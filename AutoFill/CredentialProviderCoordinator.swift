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
import GoLibs
import MBProgressHUD
import ProtonCore_Authentication
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import SwiftUI
import UIComponents
import UserNotifications

public final class CredentialProviderCoordinator {
    @KeychainStorage(key: .authSessionData)
    private var sessionData: SessionData?

    @KeychainStorage(key: .symmetricKey)
    private var symmetricKeyString: String?

    /// Self-initialized properties
    private let keychain: Keychain
    private let keymaker: Keymaker
    private var apiManager: APIManager
    private let container: NSPersistentContainer
    private let context: ASCredentialProviderExtensionContext
    private let preferences: Preferences
    private let credentialManager: CredentialManagerProtocol
    private let rootViewController: UIViewController
    private let bannerManager: BannerManager
    private let clipboardManager: ClipboardManager
    private let logManager: LogManager
    private let logger: Logger

    /// Derived properties
    private var lastChildViewController: UIViewController?
    private var symmetricKey: SymmetricKey?
    private var shareRepository: ShareRepositoryProtocol?
    private var shareEventIDRepository: ShareEventIDRepositoryProtocol?
    private var itemRepository: ItemRepositoryProtocol?
    private var shareKeyRepository: ShareKeyRepositoryProtocol?
    private var aliasRepository: AliasRepositoryProtocol?
    private var remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var currentShareId: String?
    private var credentialsViewModel: CredentialsViewModel?

    private var topMostViewController: UIViewController {
        rootViewController.topMostViewController
    }

    init(apiManager: APIManager,
         container: NSPersistentContainer,
         context: ASCredentialProviderExtensionContext,
         preferences: Preferences,
         logManager: LogManager,
         credentialManager: CredentialManagerProtocol,
         rootViewController: UIViewController) {
        let keychain = PPKeychain()
        self.keychain = keychain
        self.keymaker = .init(autolocker: Autolocker(lockTimeProvider: keychain),
                              keychain: keychain)
        self._sessionData.setKeychain(keychain)
        self._sessionData.setMainKeyProvider(keymaker)
        self._sessionData.setLogManager(logManager)
        self._symmetricKeyString.setKeychain(keychain)
        self._symmetricKeyString.setMainKeyProvider(keymaker)
        self._symmetricKeyString.setLogManager(logManager)
        self.apiManager = apiManager
        self.container = container
        self.context = context
        self.preferences = preferences
        self.logManager = logManager
        self.logger = .init(manager: logManager)
        let bannerManager = BannerManager(container: rootViewController)
        self.bannerManager = bannerManager
        self.clipboardManager = .init(preferences: preferences)
        self.credentialManager = credentialManager
        self.rootViewController = rootViewController
        self.clipboardManager.bannerManager = bannerManager
        makeSymmetricKeyAndRepositories()
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let sessionData, let symmetricKey else {
            showNoLoggedInView()
            return
        }
        apiManager.sessionIsAvailable(authCredential: sessionData.userData.credential,
                                      scopes: sessionData.userData.scopes)
        showCredentialsView(userData: sessionData.userData,
                            symmetricKey: symmetricKey,
                            serviceIdentifiers: serviceIdentifiers)
    }

    /// QuickType bar support
    func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let symmetricKey, let itemRepository,
              let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancel(errorCode: .failed)
            return
        }

        if preferences.biometricAuthenticationEnabled {
            cancel(errorCode: .userInteractionRequired)
        } else {
            Task {
                do {
                    logger.trace("Autofilling from QuickType bar")
                    let ids = try AutoFillCredential.IDs.deserializeBase64(recordIdentifier)
                    if let encryptedItem = try await itemRepository.getItem(shareId: ids.shareId,
                                                                            itemId: ids.itemId) {
                        let decryptedItem = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
                        if case .login(let data) = decryptedItem.contentData {
                            complete(quickTypeBar: true,
                                     credential: .init(user: data.username, password: data.password),
                                     encryptedItem: encryptedItem,
                                     itemRepository: itemRepository,
                                     serviceIdentifiers: [credentialIdentity.serviceIdentifier])
                        } else {
                            logger.error("Failed to autofill. Not log in item.")
                        }
                    } else {
                        logger.warning("Failed to autofill. Item not found.")
                        cancel(errorCode: .failed)
                    }
                } catch {
                    logger.error(error)
                    cancel(errorCode: .failed)
                }
            }
        }
    }

    // Biometric authentication
    func provideCredentialWithBiometricAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let symmetricKey, let itemRepository else {
            cancel(errorCode: .failed)
            return
        }

        let viewModel = LockedCredentialViewModel(itemRepository: itemRepository,
                                                  symmetricKey: symmetricKey,
                                                  credentialIdentity: credentialIdentity,
                                                  logManager: logManager)
        viewModel.onFailure = handle(error:)
        viewModel.onSuccess = { [unowned self] credential, item in
            complete(quickTypeBar: false,
                     credential: credential,
                     encryptedItem: item,
                     itemRepository: itemRepository,
                     serviceIdentifiers: [credentialIdentity.serviceIdentifier])
        }
        showView(LockedCredentialView(preferences: preferences, viewModel: viewModel))
    }

    private func handle(error: Error) {
        let defaultHandler: (Error) -> Void = { [unowned self] error in
            self.logger.error(error)
            self.alert(error: error)
        }

        guard let error = error as? PPError,
              case .credentialProvider(let reason) = error else {
            defaultHandler(error)
            return
        }

        switch reason {
        case .userCancelled:
            cancel(errorCode: .userCanceled)
            return
        case .failedToAuthenticate:
            Task {
                defer { cancel(errorCode: .failed) }
                do {
                    logger.trace("Authenticaion failed. Removing all credentials")
                    sessionData = nil
                    try await credentialManager.removeAllCredentials()
                    logger.info("Removed all credentials after authentication failure")
                } catch {
                    logger.error(error)
                }
            }
        default:
            defaultHandler(error)
        }
    }

    private func makeSymmetricKeyAndRepositories() {
        guard let sessionData,
              let symmetricKeyData = symmetricKeyString?.data(using: .utf8) else { return }

        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        let remoteAliasDatasource = RemoteAliasDatasource(apiService: apiManager.apiService)

        self.symmetricKey = symmetricKey
        self.shareRepository = ShareRepository(userData: sessionData.userData,
                                               container: container,
                                               apiService: apiManager.apiService,
                                               logManager: logManager)
        self.shareEventIDRepository = ShareEventIDRepository(container: container,
                                                             apiService: apiManager.apiService,
                                                             logManager: logManager)

        let itemRepository = ItemRepository(userData: sessionData.userData,
                                            symmetricKey: symmetricKey,
                                            container: container,
                                            apiService: apiManager.apiService,
                                            logManager: logManager)
        itemRepository.delegate = credentialManager as? ItemRepositoryDelegate
        self.itemRepository = itemRepository
        self.shareKeyRepository = ShareKeyRepository(container: container,
                                                     apiService: apiManager.apiService,
                                                     logManager: logManager,
                                                     userData: sessionData.userData)
        self.aliasRepository = AliasRepository(remoteAliasDatasouce: remoteAliasDatasource)
        self.remoteSyncEventsDatasource = RemoteSyncEventsDatasource(apiService: apiManager.apiService)
    }
}

extension CredentialProviderCoordinator {
    private func updateRank(encryptedItem: SymmetricallyEncryptedItem,
                            symmetricKey: SymmetricKey,
                            serviceIdentifiers: [ASCredentialServiceIdentifier],
                            lastUseTime: TimeInterval) async throws {
        let decryptedItem = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
        if case .login(let data) = decryptedItem.contentData {
            let serviceUrls = serviceIdentifiers
                .map { serviceIdentifier in
                    switch serviceIdentifier.type {
                    case .URL:
                        return serviceIdentifier.identifier
                    case .domain:
                        return "https://\(serviceIdentifier.identifier)"
                    @unknown default:
                        return serviceIdentifier.identifier
                    }
                }
                .compactMap { URL(string: $0) }
            let itemUrls = data.urls.compactMap { URL(string: $0) }
            let matchedUrls = itemUrls.filter { itemUrl in
                serviceUrls.contains { serviceUrl in
                    if case .matched = URLUtils.Matcher.compare(itemUrl, serviceUrl) {
                        return true
                    }
                    return false
                }
            }

            let credentials = matchedUrls
                .map { AutoFillCredential(shareId: encryptedItem.shareId,
                                          itemId: encryptedItem.item.itemID,
                                          username: data.username,
                                          url: $0.absoluteString,
                                          lastUseTime: Int64(lastUseTime)) }
            try await credentialManager.insert(credentials: credentials)
        } else {
            throw PPError.credentialProvider(.notLogInItem)
        }
    }
}

// MARK: - Context actions
private extension CredentialProviderCoordinator {
    func cancel(errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain, code: errorCode.rawValue)
        context.cancelRequest(withError: error)
    }

    func complete(quickTypeBar: Bool,
                  credential: ASPasswordCredential,
                  encryptedItem: SymmetricallyEncryptedItem,
                  itemRepository: ItemRepositoryProtocol,
                  serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        Task { @MainActor in
            do {
                let getTotpData: () -> TOTPData? = {
                    do {
                        return try encryptedItem.totpData(symmetricKey: itemRepository.symmetricKey)
                    } catch {
                        self.logger.error(error)
                        return nil
                    }
                }

                if preferences.automaticallyCopyTotpCode, let totpData = getTotpData() {
                    if quickTypeBar {
                        copyAndNotify(totpData: totpData)
                    } else {
                        if totpData.timerData.remaining <= 10 {
                            alertExpiringSoonTotpCode()
                            return // Early exit, stop AutoFill process
                        } else {
                            copyAndNotify(totpData: totpData)
                        }
                    }
                }

                context.completeRequest(withSelectedCredential: credential, completionHandler: nil)
                logger.info("Autofilled from QuickType bar \(quickTypeBar). \(encryptedItem.debugInformation)")

                let lastUseTime = Date().timeIntervalSince1970
                logger.trace("Updating rank \(encryptedItem.debugInformation)")
                try await updateRank(encryptedItem: encryptedItem,
                                     symmetricKey: itemRepository.symmetricKey,
                                     serviceIdentifiers: serviceIdentifiers,
                                     lastUseTime: lastUseTime)
                logger.info("Updated rank \(encryptedItem.debugInformation)")

                logger.trace("Updating lastUseTime \(encryptedItem.debugInformation)")
                try await itemRepository.update(item: encryptedItem,
                                                lastUseTime: lastUseTime)
                logger.info("Updated lastUseTime \(encryptedItem.debugInformation)")
            } catch {
                logger.error(error)
                if quickTypeBar {
                    cancel(errorCode: .userInteractionRequired)
                } else {
                    alert(error: error)
                }
            }
        }
    }

    func copyAndNotify(totpData: TOTPData) {
        clipboardManager.copy(text: totpData.code, bannerMessage: "")
        let content = UNMutableNotificationContent()
        content.title = "Two Factor Authentication code copied"
        if let username = totpData.username {
            content.subtitle = username
        }
        // swiftlint:disable:next line_length
        content.body = "\"\(totpData.code)\" is copied to clipboard. Expiring in \(totpData.timerData.remaining) seconds"
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil) // Deliver immediately
        UNUserNotificationCenter.current().add(request)
    }

    func alertExpiringSoonTotpCode() {
        let alert = UIAlertController(title: "Expiring soon Two Factor Authentication code",
                                      // swiftlint:disable:next line_length
                                      message: "Two Factor Authentication code for this log in item will expire in less than 10 seconds. Please try again in a few seconds.",
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        rootViewController.present(alert, animated: true)
    }
}

// MARK: - Views
private extension CredentialProviderCoordinator {
    func showView(_ view: some View) {
        if let lastChildViewController {
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
        lastChildViewController = viewController
    }

    func showCredentialsView(userData: UserData,
                             symmetricKey: SymmetricKey,
                             serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let shareRepository,
              let shareEventIDRepository,
              let itemRepository,
              let shareKeyRepository,
              let remoteSyncEventsDatasource else { return }
        let viewModel = CredentialsViewModel(userId: userData.user.ID,
                                             shareRepository: shareRepository,
                                             shareEventIDRepository: shareEventIDRepository,
                                             itemRepository: itemRepository,
                                             shareKeyRepository: shareKeyRepository,
                                             remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                                             symmetricKey: symmetricKey,
                                             serviceIdentifiers: serviceIdentifiers,
                                             logManager: logManager)
        viewModel.delegate = self
        credentialsViewModel = viewModel
        showView(CredentialsView(viewModel: viewModel, preferences: preferences))
    }

    func showNoLoggedInView() {
        let view = NotLoggedInView { [unowned self] in
            self.cancel(errorCode: .userCanceled)
        }
        showView(view)
    }

    func showCreateLoginView(shareId: String,
                             itemRepository: ItemRepositoryProtocol,
                             aliasRepository: AliasRepositoryProtocol,
                             url: URL?) {
        currentShareId = shareId

        let creationType = ItemCreationType.login(title: url?.host,
                                                  url: url?.schemeAndHost,
                                                  autofill: true)
        let emailAddress = sessionData?.userData.addresses.first?.email ?? ""
        let viewModel = CreateEditLoginViewModel(mode: .create(shareId: shareId,
                                                               type: creationType),
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository,
                                                 preferences: preferences,
                                                 logManager: logManager,
                                                 emailAddress: emailAddress)
        viewModel.delegate = self
        viewModel.createEditLoginViewModelDelegate = self
        let view = CreateEditLoginView(viewModel: viewModel)
        presentView(view)
        currentCreateEditItemViewModel = viewModel
    }

    func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate) {
        let viewModel = GeneratePasswordViewModel(mode: .createLogin)
        viewModel.delegate = delegate
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            navigationController.sheetPresentationController?.detents = [customDetent]
        } else {
            navigationController.sheetPresentationController?.detents = [.medium()]
        }
        viewModel.onDismiss = { navigationController.dismiss(animated: true) }
        presentViewController(navigationController, dismissible: true)
    }

    func showLoadingHud() {
        MBProgressHUD.showAdded(to: topMostViewController.view, animated: true)
    }

    func hideLoadingHud() {
        MBProgressHUD.hide(for: topMostViewController.view, animated: true)
    }

    func handleCreatedItem(_ itemContentType: ItemContentType) {
        topMostViewController.dismiss(animated: true) { [unowned self] in
            bannerManager.displayBottomSuccessMessage(itemContentType.creationMessage)
        }
    }

    func presentView<V: View>(_ view: V,
                              animated: Bool = true,
                              dismissible: Bool = false) {
        let viewController = UIHostingController(rootView: view)
        presentViewController(viewController)
    }

    func presentViewController(_ viewController: UIViewController,
                               animated: Bool = true,
                               dismissible: Bool = false) {
        viewController.isModalInPresentation = !dismissible
        topMostViewController.present(viewController, animated: animated)
    }

    func alert(error: Error) {
        let alert = UIAlertController(title: "Error occured",
                                      message: error.messageForTheUser,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [unowned self] _ in
            self.cancel(errorCode: .failed)
        }
        alert.addAction(cancelAction)
        rootViewController.present(alert, animated: true)
    }
}

// MARK: - CredentialsViewModelDelegate
extension CredentialProviderCoordinator: CredentialsViewModelDelegate {
    func credentialsViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func credentialsViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func credentialsViewModelWantsToCancel() {
        cancel(errorCode: .userCanceled)
    }

    func credentialsViewModelWantsToCreateLoginItem(shareId: String, url: URL?) {
        guard let itemRepository, let aliasRepository else { return }
        showCreateLoginView(shareId: shareId,
                            itemRepository: itemRepository,
                            aliasRepository: aliasRepository,
                            url: url)
    }

    func credentialsViewModelDidSelect(credential: ASPasswordCredential,
                                       item: SymmetricallyEncryptedItem,
                                       serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let itemRepository else { return }
        complete(quickTypeBar: false,
                 credential: credential,
                 encryptedItem: item,
                 itemRepository: itemRepository,
                 serviceIdentifiers: serviceIdentifiers)
    }

    func credentialsViewModelDidFail(_ error: Error) {
        handle(error: error)
    }
}

// MARK: - CreateEditItemViewModelDelegate
extension CredentialProviderCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func createEditItemViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType) {
        switch type {
        case .login:
            credentialsViewModel?.select(item: item)
        default:
            handleCreatedItem(type)
        }
    }

    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {
        print("\(#function) not applicable")
    }

    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {
        print("\(#function) not applicable")
    }

    func createEditItemViewModelDidFail(_ error: Error) {
        bannerManager.displayTopErrorMessage(error.messageForTheUser)
    }
}

// MARK: - CreateEditLoginViewModelDelegate
extension CredentialProviderCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {}

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate)
    }

    func createEditLoginViewModelWantsToOpenSettings() {
        // Not applicable
    }

    func createEditLoginViewModelCanNotCreateMoreAlias() {
        bannerManager.displayTopErrorMessage("You can not create more aliases.")
    }
}

extension SymmetricallyEncryptedItem {
    /// Get `TOTPData` of the current moment
    func totpData(symmetricKey: SymmetricKey) throws -> TOTPData? {
        let decryptedItemContent = try getDecryptedItemContent(symmetricKey: symmetricKey)
        if case .login(let logInData) = decryptedItemContent.contentData,
           !logInData.totpUri.isEmpty {
            return try .init(uri: logInData.totpUri)
        } else {
            return nil
        }
    }
}
