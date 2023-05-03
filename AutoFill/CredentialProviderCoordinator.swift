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

// swiftlint:disable file_length
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
    /// Self-initialized properties
    private let apiManager: APIManager
    private let appData: AppData
    private let bannerManager: BannerManager
    private let clipboardManager: ClipboardManager
    private let container: NSPersistentContainer
    private let context: ASCredentialProviderExtensionContext
    private let credentialManager: CredentialManagerProtocol
    private let keymaker: Keymaker
    private let logManager: LogManager
    private let logger: Logger
    private let preferences: Preferences
    private let rootViewController: UIViewController

    /// Derived properties
    private var lastChildViewController: UIViewController?
    private var symmetricKey: SymmetricKey?
    private var shareRepository: ShareRepositoryProtocol?
    private var shareEventIDRepository: ShareEventIDRepositoryProtocol?
    private var itemRepository: ItemRepositoryProtocol?
    private var favIconRepository: FavIconRepositoryProtocol?
    private var shareKeyRepository: ShareKeyRepositoryProtocol?
    private var aliasRepository: AliasRepositoryProtocol?
    private var remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol?
    private var telemetryEventRepository: TelemetryEventRepositoryProtocol?
    private var userPlanManager: UserPlanManagerProtocol?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var credentialsViewModel: CredentialsViewModel?
    private var vaultListUiModels: [VaultListUiModel]?

    private var topMostViewController: UIViewController {
        rootViewController.topMostViewController
    }

    init(context: ASCredentialProviderExtensionContext, rootViewController: UIViewController) {
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        let logManager = LogManager(module: .autoFillExtension)
        let appVersion = "ios-pass-autofill-extension@\(Bundle.main.fullAppVersionName())"
        let appData = AppData(keychain: keychain, mainKeyProvider: keymaker, logManager: logManager)
        let apiManager = APIManager(logManager: logManager, appVer: appVersion, appData: appData)
        let bannerManager = BannerManager(container: rootViewController)
        let preferences = Preferences()

        self.apiManager = apiManager
        self.appData = appData
        self.bannerManager = bannerManager
        self.clipboardManager = .init(preferences: preferences)
        self.container = .Builder.build(name: kProtonPassContainerName, inMemory: false)
        self.context = context
        self.credentialManager = CredentialManager(logManager: logManager)
        self.keymaker = keymaker
        self.logManager = logManager
        self.logger = .init(manager: logManager)
        self.preferences = preferences
        self.rootViewController = rootViewController

        // Post init
        self.clipboardManager.bannerManager = bannerManager
        self.makeSymmetricKeyAndRepositories()
        self.sendAllEventsIfApplicable()
        AppearanceSettings.apply()
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let userData = appData.userData else {
            showNotLoggedInView()
            return
        }

        do {
            let symmetricKey = try appData.getSymmetricKey()
            apiManager.sessionIsAvailable(authCredential: userData.credential,
                                          scopes: userData.scopes)
            showCredentialsView(userData: userData,
                                symmetricKey: symmetricKey,
                                serviceIdentifiers: serviceIdentifiers)
            addNewEvent(type: .autofillDisplay)
        } catch {
            alert(error: error)
        }
    }

    func configureExtension() {
        guard appData.userData != nil else {
            let view = NotLoggedInView(preferences: preferences) { [context] in
                context.completeExtensionConfigurationRequest()
            }
            showView(view)
            return
        }

        guard let itemRepository else { return }

        let viewModel = ExtensionSettingsViewModel(credentialManager: credentialManager,
                                                   itemRepository: itemRepository,
                                                   logManager: logManager,
                                                   preferences: preferences)
        viewModel.delegate = self
        let view = ExtensionSettingsView(viewModel: viewModel)
        showView(view)
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
                    appData.userData = nil
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
        guard let userData = appData.userData,
              let symmetricKey = try? appData.getSymmetricKey() else { return }
        let apiService = apiManager.apiService

        let repositoryManager = RepositoryManager(apiService: apiService,
                                                  container: container,
                                                  logManager: logManager,
                                                  symmetricKey: symmetricKey,
                                                  userData: userData)
        self.symmetricKey = symmetricKey
        self.shareRepository = repositoryManager.shareRepository
        self.shareEventIDRepository = repositoryManager.shareEventIDRepository

        let itemRepository = repositoryManager.itemRepository
        (itemRepository as? ItemRepository)?.delegate = credentialManager as? ItemRepositoryDelegate
        self.itemRepository = itemRepository
        self.favIconRepository = FavIconRepository(apiService: apiService,
                                                   containerUrl: URL.favIconsContainerURL(),
                                                   preferences: preferences,
                                                   symmetricKey: symmetricKey)
        self.shareKeyRepository = repositoryManager.shareKeyRepository
        self.aliasRepository = repositoryManager.aliasRepository
        self.remoteSyncEventsDatasource = repositoryManager.remoteSyncEventsDatasource
        self.telemetryEventRepository = TelemetryEventRepository(
            localTelemetryEventDatasource: LocalTelemetryEventDatasource(container: container),
            remoteTelemetryEventDatasource: RemoteTelemetryEventDatasource(apiService: apiService),
            userPlanProvider: UserPlanProvider(apiService: apiService, logManager: logManager),
            logManager: logManager,
            scheduler: TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                          preferences: preferences),
            userId: userData.user.ID)
    }

    func addNewEvent(type: TelemetryEventType) {
        Task {
            do {
                try await telemetryEventRepository?.addNewEvent(type: type)
            } catch {
                logger.error(error)
            }
        }
    }

    func sendAllEventsIfApplicable() {
        Task {
            do {
                try await telemetryEventRepository?.sendAllEventsIfApplicable()
            } catch {
                logger.error(error)
            }
        }
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

                if quickTypeBar {
                    addNewEvent(type: .autofillTriggeredFromSource)
                } else {
                    addNewEvent(type: .autofillTriggeredFromApp)
                }
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
              let favIconRepository,
              let shareKeyRepository,
              let remoteSyncEventsDatasource else { return }
        let viewModel = CredentialsViewModel(userId: userData.user.ID,
                                             shareRepository: shareRepository,
                                             shareEventIDRepository: shareEventIDRepository,
                                             itemRepository: itemRepository,
                                             shareKeyRepository: shareKeyRepository,
                                             remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                                             favIconRepository: favIconRepository,
                                             symmetricKey: symmetricKey,
                                             serviceIdentifiers: serviceIdentifiers,
                                             logManager: logManager)
        viewModel.delegate = self
        credentialsViewModel = viewModel
        showView(CredentialsView(viewModel: viewModel, preferences: preferences))
    }

    func showNotLoggedInView() {
        let view = NotLoggedInView(preferences: preferences) { [unowned self] in
            self.cancel(errorCode: .userCanceled)
        }
        showView(view)
    }

    // swiftlint:disable:next function_parameter_count
    func showCreateLoginView(shareId: String,
                             itemRepository: ItemRepositoryProtocol,
                             aliasRepository: AliasRepositoryProtocol,
                             userPlanManager: UserPlanManagerProtocol,
                             vaults: [Vault],
                             url: URL?) {
        do {
            let creationType = ItemCreationType.login(title: url?.host,
                                                      url: url?.schemeAndHost,
                                                      autofill: true)
            let emailAddress = appData.userData?.addresses.first?.email ?? ""
            let viewModel = try CreateEditLoginViewModel(mode: .create(shareId: shareId,
                                                                       type: creationType),
                                                         itemRepository: itemRepository,
                                                         aliasRepository: aliasRepository,
                                                         userPlanManager: userPlanManager,
                                                         vaults: vaults,
                                                         preferences: preferences,
                                                         logManager: logManager,
                                                         emailAddress: emailAddress)
            viewModel.delegate = self
            viewModel.createEditLoginViewModelDelegate = self
            let view = CreateEditLoginView(viewModel: viewModel)
            present(view)
            currentCreateEditItemViewModel = viewModel
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func showGeneratePasswordView(delegate: GeneratePasswordViewModelDelegate) {
        let viewModel = GeneratePasswordViewModel(mode: .createLogin)
        viewModel.delegate = delegate
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                344
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        present(viewController, dismissible: true)
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

    func present<V: View>(_ view: V, animated: Bool = true, dismissible: Bool = false) {
        let viewController = UIHostingController(rootView: view)
        present(viewController)
    }

    func present(_ viewController: UIViewController, animated: Bool = true, dismissible: Bool = false) {
        viewController.isModalInPresentation = !dismissible
        viewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        topMostViewController.present(viewController, animated: animated)
    }

    func alert(error: Error) {
        let alert = UIAlertController(title: "Error occured",
                                      message: error.localizedDescription,
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

    func credentialsViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                        delegate: SortTypeListViewModelDelegate) {
        let viewModel = SortTypeListViewModel(sortType: selectedSortType)
        viewModel.delegate = delegate
        let view = SortTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.compact.value) * SortType.allCases.count + 60
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }

        present(viewController, dismissible: true)
    }

    func credentialsViewModelWantsToCreateLoginItem(shareId: String, url: URL?) {
        guard let itemRepository,
              let aliasRepository,
              let shareRepository,
              let userPlanManager else { return }
        if let vaultListUiModels {
            showCreateLoginView(shareId: shareId,
                                itemRepository: itemRepository,
                                aliasRepository: aliasRepository,
                                userPlanManager: userPlanManager,
                                vaults: vaultListUiModels.map { $0.vault },
                                url: url)
        } else {
            Task { @MainActor in
                do {
                    showLoadingHud()
                    let items = try await itemRepository.getAllItems()
                    let vaults = try await shareRepository.getVaults()

                    self.vaultListUiModels = vaults.map { vault in
                        let activeItems =
                        items.filter { $0.item.itemState == .active && $0.shareId == vault.shareId }
                        return .init(vault: vault, itemCount: activeItems.count)
                    }
                    hideLoadingHud()
                    credentialsViewModelWantsToCreateLoginItem(shareId: shareId, url: url)
                } catch {
                    logger.error(error)
                    hideLoadingHud()
                    bannerManager.displayTopErrorMessage(error)
                }
            }
        }
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

    func createEditItemViewModelWantsToChangeVault(selectedVault: Vault,
                                                   delegate: VaultSelectorViewModelDelegate) {
        guard let vaultListUiModels else { return }
        let viewModel = VaultSelectorViewModel(allVaults: vaultListUiModels, selectedVault: selectedVault)
        viewModel.delegate = delegate
        let view = VaultSelectorView(viewModel: viewModel)
        present(view)
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType) {
        switch type {
        case .login:
            credentialsViewModel?.select(item: item)
        default:
            handleCreatedItem(type)
        }
        addNewEvent(type: .create(type))
    }

    // Not applicable
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {}

    // Not applicable
    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {}

    func createEditItemViewModelDidFail(_ error: Error) {
        bannerManager.displayTopErrorMessage(error.localizedDescription)
    }
}

// MARK: - CreateEditLoginViewModelDelegate
extension CredentialProviderCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        viewModel.delegate = self
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        present(viewController, dismissible: true)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate)
    }

    // Not applicable
    func createEditLoginViewModelWantsToOpenSettings() {}

    func createEditLoginViewModelWantsToUpgrade() {
        print("Handle this")
    }
}

// MARK: - CreateAliasLiteViewModelDelegate
extension CredentialProviderCoordinator: CreateAliasLiteViewModelDelegate {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        let view = MailboxSelectionView(mailboxSelection: mailboxSelection,
                                        mode: .createAliasLite,
                                        titleMode: .create)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium(), .large()]
        present(viewController)
    }

    func createAliasLiteViewModelWantsToUpgrade() {
        print("Handle this")
    }
}

// MARK: - ExtensionSettingsViewModelDelegate
extension CredentialProviderCoordinator: ExtensionSettingsViewModelDelegate {
    func extensionSettingsViewModelWantsToShowSpinner() {
        showLoadingHud()
    }

    func extensionSettingsViewModelWantsToHideSpinner() {
        hideLoadingHud()
    }

    func extensionSettingsViewModelWantsToDismiss() {
        context.completeExtensionConfigurationRequest()
    }

    func extensionSettingsViewModelWantsToLogOut() {
        appData.userData = nil
        appData.userPlan = nil
        context.completeExtensionConfigurationRequest()
    }

    func extensionSettingsViewModelDidEncounter(error: Error) {
        bannerManager.displayTopErrorMessage(error)
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
