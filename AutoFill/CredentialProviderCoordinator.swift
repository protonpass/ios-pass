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
import Combine
import Core
import CoreData
import CryptoKit
import DesignSystem
import Entities
import Factory
import MBProgressHUD
import ProtonCoreAuthentication
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices
import Sentry
import SwiftUI

public final class CredentialProviderCoordinator: DeinitPrintable {
    deinit {
        print(deinitMessage)
    }

    /// Self-initialized properties
    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let credentialProvider = resolve(\SharedDataContainer.credentialProvider)
    private let preferences = resolve(\SharedToolingContainer.preferences)
    private let setUpSentry = resolve(\SharedUseCasesContainer.setUpSentry)

    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let corruptedSessionEventStream = resolve(\SharedDataStreamContainer.corruptedSessionEventStream)

    private let context = resolve(\AutoFillDataContainer.context)
    private weak var rootViewController: UIViewController?
    private var cancellables = Set<AnyCancellable>()

    // Use cases
    private let cancelAutoFill = resolve(\AutoFillUseCaseContainer.cancelAutoFill)
    private let wipeAllData = resolve(\SharedUseCasesContainer.wipeAllData)

    // Lazily injected because some use cases are dependent on repositories
    // which are not registered when the user is not logged in
    @LazyInjected(\SharedUseCasesContainer.addTelemetryEvent) private var addTelemetryEvent
    @LazyInjected(\SharedUseCasesContainer.indexAllLoginItems) private var indexAllLoginItems
    @LazyInjected(\AutoFillUseCaseContainer.completeAutoFill) private var completeAutoFill
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedServiceContainer.upgradeChecker) private var upgradeChecker
    @LazyInjected(\SharedServiceContainer.vaultsManager) private var vaultsManager
    @LazyInjected(\SharedUseCasesContainer.revokeCurrentSession) private var revokeCurrentSession

    /// Derived properties
    private var lastChildViewController: UIViewController?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var credentialsViewModel: CredentialsViewModel?
    private var generatePasswordCoordinator: GeneratePasswordCoordinator?
    private var customCoordinator: CustomCoordinator?

    private var topMostViewController: UIViewController? {
        rootViewController?.topMostViewController
    }

    init(rootViewController: UIViewController) {
        SharedViewContainer.shared.register(rootViewController: rootViewController)
        self.rootViewController = rootViewController

        // Post init
        setUpSentry(bundle: .main)
        AppearanceSettings.apply()
        setUpRouting()

        apiManager.sessionWasInvalidated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionUID in
                guard let self else { return }
                logOut(error: PassError.unexpectedLogout, sessionId: sessionUID)
            }
            .store(in: &cancellables)

        corruptedSessionEventStream
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reason in
                guard let self else { return }
                logOut(error: PassError.corruptedSession(reason), sessionId: reason.sessionId)
            }
            .store(in: &cancellables)
    }

    func start(with serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        guard credentialProvider.isAuthenticated else {
            showNotLoggedInView()
            return
        }

        showCredentialsView(serviceIdentifiers: serviceIdentifiers)
        addNewEvent(type: .autofillDisplay)
    }

    func configureExtension() {
        guard credentialProvider.isAuthenticated else {
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
        guard let recordIdentifier = credentialIdentity.recordIdentifier else {
            cancelAutoFill(reason: .failed)
            return
        }
        guard preferences.localAuthenticationMethod == .none else {
            cancelAutoFill(reason: .userInteractionRequired)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                logger.trace("Autofilling from QuickType bar")
                let ids = try AutoFillCredential.IDs.deserializeBase64(recordIdentifier)
                if Task.isCancelled {
                    cancelAutoFill(reason: .failed)
                }
                if let itemContent = try await itemRepository.getItemContent(shareId: ids.shareId,
                                                                             itemId: ids.itemId) {
                    if Task.isCancelled {
                        cancelAutoFill(reason: .failed)
                    }
                    if case let .login(data) = itemContent.contentData {
                        if Task.isCancelled {
                            cancelAutoFill(reason: .credentialIdentityNotFound)
                        }
                        try await completeAutoFill(quickTypeBar: true,
                                                   identifiers: [credentialIdentity.serviceIdentifier],
                                                   credential: .init(user: data.username,
                                                                     password: data.password),
                                                   itemContent: itemContent)
                    } else {
                        logger.error("Failed to autofill. Not log in item.")
                        cancelAutoFill(reason: .credentialIdentityNotFound)
                    }
                } else {
                    logger.warning("Failed to autofill. Item not found.")
                    cancelAutoFill(reason: .failed)
                }
            } catch {
                logger.error(error)
                cancelAutoFill(reason: .failed)
            }
        }
    }

    // Biometric authentication
    func provideCredentialWithBiometricAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) {
        let viewModel = LockedCredentialViewModel(credentialIdentity: credentialIdentity)
        viewModel.onFailure = { [weak self] error in
            guard let self else { return }
            handle(error: error)
        }
        viewModel.onSuccess = { [weak self] credential, itemContent in
            guard let self else { return }
            Task { [weak self] in
                guard let self else { return }

                try? await completeAutoFill(quickTypeBar: false,
                                            identifiers: [credentialIdentity.serviceIdentifier],
                                            credential: credential,
                                            itemContent: itemContent)
            }
        }
        showView(LockedCredentialView(preferences: preferences, viewModel: viewModel))
    }
}

// MARK: - Setup & Utils

private extension CredentialProviderCoordinator {
    // swiftlint:disable cyclomatic_complexity
    func setUpRouting() {
        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case .upgradeFlow:
                    startUpgradeFlow()
                case let .suffixView(suffixSelection):
                    createAliasLiteViewModelWantsToSelectSuffix(suffixSelection)
                case let .mailboxView(mailboxSelection, _):
                    createAliasLiteViewModelWantsToSelectMailboxes(mailboxSelection)
                case .vaultSelection:
                    createEditItemViewModelWantsToChangeVault()
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
                        showLoadingHud()
                    } else {
                        hideLoadingHud()
                    }
                case let .displayErrorBanner(error):
                    bannerManager.displayTopErrorMessage(error)
                default:
                    return
                }
            }
            .store(in: &cancellables)
    }

    func handle(error: Error) {
        let defaultHandler: (Error) -> Void = { [weak self] error in
            guard let self else { return }
            logger.error(error)
            alert(error: error)
        }

        guard let error = error as? PassError,
              case let .credentialProvider(reason) = error else {
            defaultHandler(error)
            return
        }

        switch reason {
        case .userCancelled:
            cancelAutoFill(reason: .userCanceled)
            return
        case .failedToAuthenticate:
            logOut { [weak self] in
                guard let self else { return }
                cancelAutoFill(reason: .failed)
            }

        default:
            defaultHandler(error)
        }
    }

    func addNewEvent(type: TelemetryEventType) {
        addTelemetryEvent(with: type)
    }

    func logOut(error: Error? = nil,
                sessionId: String? = nil,
                completion: (() -> Void)? = nil) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let error {
                SentrySDK.capture(error: error) { scope in
                    if let sessionId {
                        scope.setTag(value: sessionId, key: "sessionUID")
                    }
                }
            }
            await revokeCurrentSession()
            await wipeAllData(isTests: false)
            showNotLoggedInView()
            completion?()
        }
    }
}

// MARK: - Views for routing

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

    func showCredentialsView(serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        let viewModel = CredentialsViewModel(serviceIdentifiers: serviceIdentifiers)
        viewModel.delegate = self
        credentialsViewModel = viewModel
        showView(CredentialsView(viewModel: viewModel))
    }

    func showNotLoggedInView() {
        let view = NotLoggedInView { [weak self] in
            guard let self else { return }
            cancelAutoFill(reason: .userCanceled)
        }
        showView(view)
    }

    func showCreateLoginView(shareId: String,
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
        let coordinator = GeneratePasswordCoordinator(generatePasswordViewModelDelegate: delegate,
                                                      mode: .createLogin)
        coordinator.delegate = self
        coordinator.start()
        generatePasswordCoordinator = coordinator
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
            guard let self else { return }
            bannerManager.displayBottomSuccessMessage(itemContentType.creationMessage)
        }
    }

    func present(_ view: some View) {
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
            guard let self else { return }
            cancelAutoFill(reason: .failed)
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
            guard let self else { return }
            rootViewController?.present(alert, animated: true)
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

    func credentialsViewModelWantsToLogOut() {
        logOut()
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
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                showLoadingHud()
                if vaultsManager.getAllVaultContents().isEmpty {
                    try await vaultsManager.asyncRefresh()
                }
                let vaults = vaultsManager.getAllVaultContents()

                hideLoadingHud()
                showCreateLoginView(shareId: shareId,
                                    upgradeChecker: upgradeChecker,
                                    vaults: vaults.map(\.vault),
                                    url: url)
            } catch {
                logger.error(error)
                hideLoadingHud()
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func credentialsViewModelDidSelect(credential: ASPasswordCredential,
                                       itemContent: ItemContent,
                                       serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await completeAutoFill(quickTypeBar: false,
                                           identifiers: serviceIdentifiers,
                                           credential: credential,
                                           itemContent: itemContent)
            } catch {
                cancelAutoFill(reason: .failed)
            }
        }
    }
}

// MARK: - CreateEditItemViewModelDelegate

extension CredentialProviderCoordinator: CreateEditItemViewModelDelegate {
    func createEditItemViewModelWantsToChangeVault() {
        guard let rootViewController else { return }
        let viewModel = VaultSelectorViewModel()

        let view = VaultSelectorView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        let customHeight = 66 * vaultsManager.getVaultCount() + 180 // Space for upsell banner
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
                    try await indexAllLoginItems(ignorePreferences: false)
                    credentialsViewModel?.select(item: item)
                } catch {
                    logger.error(error)
                }
            }
        default:
            handleCreatedItem(type)
        }
        addNewEvent(type: .create(type))
    }

    // Not applicable
    func createEditItemViewModelDidUpdateItem(_ type: ItemContentType) {}
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
        logOut { [weak self] in
            guard let self else { return }
            context.completeExtensionConfigurationRequest()
        }
    }
}

// swiftlint:enable cyclomatic_complexity
