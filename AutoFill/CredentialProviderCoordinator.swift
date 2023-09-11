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
import Combine
import Core
import CoreData
import CryptoKit
import DesignSystem
import Factory
import MBProgressHUD
import ProtonCoreAuthentication
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices
import SwiftUI

public final class CredentialProviderCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    /// Self-initialized properties
    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let appData = resolve(\SharedDataContainer.appData)
    private let logManager = resolve(\SharedToolingContainer.logManager)
    private let preferences = resolve(\SharedToolingContainer.preferences)

    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let bannerManager: BannerManager
    private let container: NSPersistentContainer
    private let context = resolve(\AutoFillDataContainer.context)
    private weak var rootViewController: UIViewController?
    private var cancellables = Set<AnyCancellable>()

    // Use cases
    private let cancelAutoFill = resolve(\AutoFillUseCaseContainer.cancelAutoFill)
    private let unindexAllLoginItems = resolve(\SharedUseCasesContainer.unindexAllLoginItems)

    // Lazily injected because some use cases are dependent on repositories
    // which are not registered when the user is not logged in
    @LazyInjected(\SharedUseCasesContainer.addTelemetryEvent) private var addTelemetryEvent
    @LazyInjected(\SharedUseCasesContainer.indexAllLoginItems) private var indexAllLoginItems
    @LazyInjected(\AutoFillUseCaseContainer.completeAutoFill) private var completeAutoFill

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
    private var upgradeChecker: UpgradeCheckerProtocol?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var credentialsViewModel: CredentialsViewModel?
    private var vaultListUiModels: [VaultListUiModel]?
    private var aliasCount: Int?
    private var vaultCount: Int?
    private var totpCount: Int?

    private var wordProvider: WordProviderProtocol?
    private var generatePasswordCoordinator: GeneratePasswordCoordinator?
    private var customCoordinator: CustomCoordinator?

    private var topMostViewController: UIViewController? {
        rootViewController?.topMostViewController
    }

    init(rootViewController: UIViewController) {
        bannerManager = .init(container: rootViewController)
        container = .Builder.build(name: kProtonPassContainerName, inMemory: false)
        self.rootViewController = rootViewController

        // Post init
        clipboardManager.bannerManager = bannerManager
        makeSymmetricKeyAndRepositories()
        sendAllEventsIfApplicable()
        AppearanceSettings.apply()
        setUpRouting()
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let userData = appData.userData else {
            showNotLoggedInView()
            return
        }

        do {
            let symmetricKey = try appData.getSymmetricKey()
            SharedDataContainer.shared.register(container: container,
                                                symmetricKey: symmetricKey,
                                                userData: userData,
                                                manualLogIn: false)
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
            let notLoggedInView = NotLoggedInView { [context] in
                context.completeExtensionConfigurationRequest()
            }
            showView(notLoggedInView)
            return
        }

        let viewModel = ExtensionSettingsViewModel()
        viewModel.delegate = self
        let settingsView = ExtensionSettingsView(viewModel: viewModel)
        showView(settingsView)
    }

    /// QuickType bar support
    func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let itemRepository,
              let upgradeChecker,
              let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancelAutoFill(reason: .failed)
            return
        }

        if preferences.localAuthenticationMethod != .none {
            cancelAutoFill(reason: .userInteractionRequired)
        } else {
            Task { [weak self] in
                guard let self else { return }
                do {
                    self.logger.trace("Autofilling from QuickType bar")
                    let ids = try AutoFillCredential.IDs.deserializeBase64(recordIdentifier)
                    if let itemContent = try await itemRepository.getItemContent(shareId: ids.shareId,
                                                                                 itemId: ids.itemId) {
                        if case let .login(data) = itemContent.contentData {
                            self.complete(quickTypeBar: true,
                                          credential: .init(user: data.username, password: data.password),
                                          itemContent: itemContent,
                                          itemRepository: itemRepository,
                                          upgradeChecker: upgradeChecker,
                                          serviceIdentifiers: [credentialIdentity.serviceIdentifier])
                        } else {
                            self.logger.error("Failed to autofill. Not log in item.")
                        }
                    } else {
                        self.logger.warning("Failed to autofill. Item not found.")
                        self.cancelAutoFill(reason: .failed)
                    }
                } catch {
                    self.logger.error(error)
                    self.cancelAutoFill(reason: .failed)
                }
            }
        }
    }

    // Biometric authentication
    func provideCredentialWithBiometricAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let symmetricKey, let itemRepository, let upgradeChecker else {
            cancelAutoFill(reason: .failed)
            return
        }

        let viewModel = LockedCredentialViewModel(itemRepository: itemRepository,
                                                  symmetricKey: symmetricKey,
                                                  credentialIdentity: credentialIdentity)
        viewModel.onFailure = { [weak self] error in
            self?.handle(error: error)
        }
        viewModel.onSuccess = { [weak self] credential, itemContent in
            self?.complete(quickTypeBar: false,
                           credential: credential,
                           itemContent: itemContent,
                           itemRepository: itemRepository,
                           upgradeChecker: upgradeChecker,
                           serviceIdentifiers: [credentialIdentity.serviceIdentifier])
        }
        showView(LockedCredentialView(preferences: preferences, viewModel: viewModel))
    }

    private func handle(error: Error) {
        let defaultHandler: (Error) -> Void = { [weak self] error in
            self?.logger.error(error)
            self?.alert(error: error)
        }

        guard let error = error as? PPError,
              case let .credentialProvider(reason) = error else {
            defaultHandler(error)
            return
        }

        switch reason {
        case .userCancelled:
            cancelAutoFill(reason: .userCanceled)
            return
        case .failedToAuthenticate:
            Task { [weak self] in
                guard let self else { return }
                defer { self.cancelAutoFill(reason: .failed) }
                do {
                    self.logger.trace("Authenticaion failed. Removing all credentials")
                    self.appData.userData = nil
                    try await self.unindexAllLoginItems()
                    self.logger.info("Removed all credentials after authentication failure")
                } catch {
                    self.logger.error(error)
                }
            }
        default:
            defaultHandler(error)
        }
    }

    final class WeakLimitationCounter: LimitationCounterProtocol {
        weak var actualCounter: LimitationCounterProtocol?

        init(actualCounter: LimitationCounterProtocol? = nil) {
            self.actualCounter = actualCounter
        }

        func getAliasCount() -> Int {
            actualCounter?.getAliasCount() ?? 0
        }

        func getVaultCount() -> Int {
            actualCounter?.getVaultCount() ?? 0
        }

        func getTOTPCount() -> Int {
            actualCounter?.getTOTPCount() ?? 0
        }
    }

    private func makeSymmetricKeyAndRepositories() {
        guard let userData = appData.userData,
              let symmetricKey = try? appData.getSymmetricKey() else { return }
        SharedDataContainer.shared.register(container: container,
                                            symmetricKey: symmetricKey,
                                            userData: userData,
                                            manualLogIn: false)
        let apiService = apiManager.apiService

        let repositoryManager = RepositoryManager(apiService: apiService,
                                                  container: container,
                                                  currentDateProvider: CurrentDateProvider(),
                                                  limitationCounter: WeakLimitationCounter(actualCounter: self),
                                                  logManager: logManager,
                                                  symmetricKey: symmetricKey,
                                                  userData: userData,
                                                  telemetryThresholdProvider: preferences)
        self.symmetricKey = symmetricKey
        shareRepository = repositoryManager.shareRepository
        shareEventIDRepository = repositoryManager.shareEventIDRepository

        itemRepository = repositoryManager.itemRepository
        favIconRepository = FavIconRepository(apiService: apiService,
                                              containerUrl: URL.favIconsContainerURL(),
                                              settings: preferences,
                                              symmetricKey: symmetricKey)
        shareKeyRepository = repositoryManager.shareKeyRepository
        aliasRepository = repositoryManager.aliasRepository
        remoteSyncEventsDatasource = repositoryManager.remoteSyncEventsDatasource
        telemetryEventRepository = repositoryManager.telemetryEventRepository
        upgradeChecker = repositoryManager.upgradeChecker
    }

    func addNewEvent(type: TelemetryEventType) {
        addTelemetryEvent(with: type)
    }

    func sendAllEventsIfApplicable() {
        Task { [weak self] in
            do {
                try await self?.telemetryEventRepository?.sendAllEventsIfApplicable()
            } catch {
                self?.logger.error(error)
            }
        }
    }
}

private extension CredentialProviderCoordinator {
    func setUpRouting() {
        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case .upgradeFlow:
                    self.startUpgradeFlow()
                case let .suffixView(suffixSelection):
                    self.createAliasLiteViewModelWantsToSelectSuffix(suffixSelection)
                case let .mailboxView(mailboxSelection, _):
                    self.createAliasLiteViewModelWantsToSelectMailboxes(mailboxSelection)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        router
            .globalElementDisplay
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .globalLoading(shouldShow):
                    if shouldShow {
                        self.showLoadingHud()
                    } else {
                        self.hideLoadingHud()
                    }
                case let .displayErrorBanner(error):
                    self.bannerManager.displayTopErrorMessage(error)
                }
            }
            .store(in: &cancellables)
    }
}

private extension CredentialProviderCoordinator {
    // swiftlint:disable:next function_parameter_count
    func complete(quickTypeBar: Bool,
                  credential: ASPasswordCredential,
                  itemContent: ItemContent,
                  itemRepository: ItemRepositoryProtocol,
                  upgradeChecker: UpgradeCheckerProtocol,
                  serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        completeAutoFill(quickTypeBar: quickTypeBar,
                         credential: credential,
                         itemContent: itemContent,
                         itemRepository: itemRepository,
                         upgradeChecker: upgradeChecker,
                         serviceIdentifiers: serviceIdentifiers,
                         telemetryEventRepository: telemetryEventRepository)
    }
}

// MARK: - Views

private extension CredentialProviderCoordinator {
    func showView(_ view: some View) {
        guard let rootViewController else {
            return
        }
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
              let upgradeChecker,
              let favIconRepository,
              let shareKeyRepository,
              let remoteSyncEventsDatasource else { return }
        let viewModel = CredentialsViewModel(userId: userData.user.ID,
                                             shareRepository: shareRepository,
                                             shareEventIDRepository: shareEventIDRepository,
                                             itemRepository: itemRepository,
                                             upgradeChecker: upgradeChecker,
                                             shareKeyRepository: shareKeyRepository,
                                             remoteSyncEventsDatasource: remoteSyncEventsDatasource,
                                             favIconRepository: favIconRepository,
                                             symmetricKey: symmetricKey,
                                             serviceIdentifiers: serviceIdentifiers)
        viewModel.delegate = self
        credentialsViewModel = viewModel
        showView(CredentialsView(viewModel: viewModel))
    }

    func showNotLoggedInView() {
        let view = NotLoggedInView { [weak self] in
            self?.cancelAutoFill(reason: .userCanceled)
        }
        showView(view)
    }

    // swiftlint:disable:next function_parameter_count
    func showCreateLoginView(shareId: String,
                             itemRepository: ItemRepositoryProtocol,
                             aliasRepository: AliasRepositoryProtocol,
                             upgradeChecker: UpgradeCheckerProtocol,
                             vaults: [Vault],
                             url: URL?) {
        do {
            let creationType = ItemCreationType.login(title: url?.host,
                                                      url: url?.schemeAndHost,
                                                      autofill: true)
            let viewModel = try CreateEditLoginViewModel(mode: .create(shareId: shareId,
                                                                       type: creationType),
                                                         upgradeChecker: upgradeChecker,
                                                         vaults: vaults)
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
        if let wordProvider {
            let coordinator = GeneratePasswordCoordinator(generatePasswordViewModelDelegate: delegate,
                                                          mode: .createLogin,
                                                          wordProvider: wordProvider)
            coordinator.delegate = self
            coordinator.start()
            generatePasswordCoordinator = coordinator
        } else {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    let wordProvider = try await WordProvider()
                    self.wordProvider = wordProvider
                    self.showGeneratePasswordView(delegate: delegate)
                } catch {
                    self.logger.error(error)
                    self.bannerManager.displayTopErrorMessage(error)
                }
            }
        }
    }

    func showLoadingHud() {
        guard let topMostViewController else {
            return
        }
        MBProgressHUD.showAdded(to: topMostViewController.view, animated: true)
    }

    func hideLoadingHud() {
        guard let topMostViewController else {
            return
        }
        MBProgressHUD.hide(for: topMostViewController.view, animated: true)
    }

    func handleCreatedItem(_ itemContentType: ItemContentType) {
        topMostViewController?.dismiss(animated: true) { [weak self] in
            self?.bannerManager.displayBottomSuccessMessage(itemContentType.creationMessage)
        }
    }

    func present(_ view: some View, animated: Bool = true, dismissible: Bool = false) {
        let viewController = UIHostingController(rootView: view)
        present(viewController)
    }

    func present(_ viewController: UIViewController, animated: Bool = true, dismissible: Bool = false) {
        viewController.isModalInPresentation = !dismissible
        viewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        topMostViewController?.present(viewController, animated: animated)
    }

    func alert(error: Error) {
        let alert = UIAlertController(title: "Error occured",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.cancelAutoFill(reason: .failed)
        }
        alert.addAction(cancelAction)
        rootViewController?.present(alert, animated: true)
    }

    func startUpgradeFlow() {
        let alert = UIAlertController(title: "Upgrade",
                                      message: "Please open Proton Pass app to upgrade",
                                      preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okButton)
        rootViewController?.dismiss(animated: true) { [weak self] in
            self?.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - GeneratePasswordCoordinatorDelegate

extension CredentialProviderCoordinator: GeneratePasswordCoordinatorDelegate {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController) {
        present(viewController)
    }
}

// MARK: - CredentialsViewModelDelegate

extension CredentialProviderCoordinator: CredentialsViewModelDelegate {
    func credentialsViewModelWantsToCancel() {
        cancelAutoFill(reason: .userCanceled)
    }

    func credentialsViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                        delegate: SortTypeListViewModelDelegate) {
        guard let rootViewController else {
            return
        }
        let viewModel = SortTypeListViewModel(sortType: selectedSortType)
        viewModel.delegate = delegate
        let view = SortTypeListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * SortType.allCases.count + 60
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController, dismissible: true)
    }

    func credentialsViewModelWantsToCreateLoginItem(shareId: String, url: URL?) {
        guard let itemRepository,
              let aliasRepository,
              let shareRepository,
              let upgradeChecker,
              let symmetricKey else { return }
        if let vaultListUiModels {
            showCreateLoginView(shareId: shareId,
                                itemRepository: itemRepository,
                                aliasRepository: aliasRepository,
                                upgradeChecker: upgradeChecker,
                                vaults: vaultListUiModels.map(\.vault),
                                url: url)
        } else {
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    self.showLoadingHud()
                    let items = try await itemRepository.getAllItems()
                    let vaults = try await shareRepository.getVaults()

                    self.aliasCount = items.filter { $0.item.aliasEmail != nil }.count

                    self.vaultListUiModels = vaults.map { vault in
                        let activeItems =
                            items.filter { $0.item.itemState == .active && $0.shareId == vault.shareId }
                        return .init(vault: vault, itemCount: activeItems.count)
                    }

                    self.vaultCount = vaults.count

                    self.totpCount = try items
                        .filter(\.isLogInItem)
                        .map { try $0.toItemUiModel(symmetricKey) }
                        .filter(\.hasTotpUri)
                        .count

                    self.hideLoadingHud()
                    self.credentialsViewModelWantsToCreateLoginItem(shareId: shareId, url: url)
                } catch {
                    self.logger.error(error)
                    self.hideLoadingHud()
                    self.bannerManager.displayTopErrorMessage(error)
                }
            }
        }
    }

    func credentialsViewModelDidSelect(credential: ASPasswordCredential,
                                       itemContent: ItemContent,
                                       serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard let itemRepository, let upgradeChecker else { return }
        complete(quickTypeBar: false,
                 credential: credential,
                 itemContent: itemContent,
                 itemRepository: itemRepository,
                 upgradeChecker: upgradeChecker,
                 serviceIdentifiers: serviceIdentifiers)
    }
}

// MARK: - CreateEditItemViewModelDelegate

extension CredentialProviderCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToChangeVault(selectedVault: Vault,
                                                   delegate: VaultSelectorViewModelDelegate) {
        guard let vaultListUiModels, let rootViewController else { return }
        let viewModel = VaultSelectorViewModel(allVaults: vaultListUiModels,
                                               selectedVault: selectedVault)
        viewModel.delegate = delegate
        let view = VaultSelectorView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * vaultListUiModels.count + 180 // Space for upsell banner
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController, dismissible: true)
    }

    func createEditItemViewModelWantsToAddCustomField(delegate: CustomFieldAdditionDelegate) {
        guard let rootViewController else {
            return
        }
        customCoordinator = CustomFieldAdditionCoordinator(rootViewController: rootViewController,
                                                           delegate: delegate)
        customCoordinator?.start()
    }

    func createEditItemViewModelWantsToEditCustomFieldTitle(_ uiModel: CustomFieldUiModel,
                                                            delegate: CustomFieldEditionDelegate) {
        guard let rootViewController else {
            return
        }
        customCoordinator = CustomFieldEditionCoordinator(rootViewController: rootViewController,
                                                          delegate: delegate,
                                                          uiModel: uiModel)
        customCoordinator?.start()
    }

    func createEditItemViewModelDidCreateItem(_ item: SymmetricallyEncryptedItem,
                                              type: ItemContentType) {
        switch type {
        case .login:
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.indexAllLoginItems(ignorePreferences: false)
                    self.credentialsViewModel?.select(item: item)
                } catch {
                    self.logger.error(error)
                }
            }
        default:
            handleCreatedItem(type)
        }
        addNewEvent(type: .create(type))
    }

    // Not applicable
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {}

    // Not applicable
    func createEditItemViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType) {}
}

// MARK: - CreateEditLoginViewModelDelegate

extension CredentialProviderCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController, dismissible: true)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate) {
        showGeneratePasswordView(delegate: delegate)
    }
}

// MARK: - CreateAliasLiteViewModelDelegate

extension CredentialProviderCoordinator {
    func createAliasLiteViewModelWantsToSelectMailboxes(_ mailboxSelection: MailboxSelection) {
        guard let rootViewController else { return }
        let viewModel = MailboxSelectionViewModel(mailboxSelection: mailboxSelection,
                                                  mode: .createAliasLite,
                                                  titleMode: .create)
        let view = MailboxSelectionView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * mailboxSelection.mailboxes.count + 150
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func createAliasLiteViewModelWantsToSelectSuffix(_ suffixSelection: SuffixSelection) {
        guard let rootViewController else { return }
        let viewModel = SuffixSelectionViewModel(suffixSelection: suffixSelection)
        let view = SuffixSelectionView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.compact.value) * suffixSelection.suffixes.count + 100
        viewController.setDetentType(.customAndLarge(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }
}

// MARK: ExtensionSettingsViewModelDelegate

extension CredentialProviderCoordinator: ExtensionSettingsViewModelDelegate {
    func extensionSettingsViewModelWantsToDismiss() {
        context.completeExtensionConfigurationRequest()
    }

    func extensionSettingsViewModelWantsToLogOut() {
        appData.userData = nil
        context.completeExtensionConfigurationRequest()
    }
}

// MARK: - LimitationCounterProtocol

extension CredentialProviderCoordinator: LimitationCounterProtocol {
    public func getAliasCount() -> Int {
        guard let aliasCount else { return 0 }
        return aliasCount
    }

    public func getVaultCount() -> Int {
        guard let vaultCount else { return 0 }
        return vaultCount
    }

    public func getTOTPCount() -> Int {
        guard let totpCount else { return 0 }
        return totpCount
    }
}
