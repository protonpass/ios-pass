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

@preconcurrency import AuthenticationServices
import Client
@preconcurrency import Combine
import Core
import DesignSystem
import DIComposition
import Entities
import FactoryKit
import Macro
import Screens
import Stores
import SwiftUI

typealias UserForNewItemSubject = PassthroughSubject<UserUiModel, Never>

extension ASCredentialProviderExtensionContext: @unchecked @retroactive Sendable {}

@MainActor
final class CredentialProviderCoordinator: DeinitPrintable {
    /// Self-initialized properties
    private let setUpSentry = dependency(\UseCasesContainer.setUpSentry)
    private let setCoreLoggerEnvironment = dependency(\UseCasesContainer.setCoreLoggerEnvironment)
    private let logger = dependency(\ToolingContainer.logger)
    private let router = dependency(\RouterContainer.mainUIKitSwiftUIRouter)
    private let userForNewItemSubject = UserForNewItemSubject()

    private weak var rootViewController: UIViewController?
    private weak var context: ASCredentialProviderExtensionContext?
    private var cancellables = Set<AnyCancellable>()

    // Use cases
    private let completeConfiguration = dependency(\AutoFillUseCaseContainer.completeConfiguration)
    private let cancelAutoFill = dependency(\AutoFillUseCaseContainer.cancelAutoFill)
    private let sendErrorToSentry = dependency(\UseCasesContainer.sendErrorToSentry)

    // Lazily injected because some use cases are dependent on repositories
    // which are not registered when the user is not logged in
    @LazyInjected(\UseCasesContainer.addTelemetryEvent) private var addTelemetryEvent
    @LazyInjected(\UseCasesContainer.indexAllLoginItems) private var indexAllLoginItems
    @LazyInjected(\AutoFillUseCaseContainer.checkAndAutoFill) private var checkAndAutoFill
    @LazyInjected(\AutoFillUseCaseContainer.completeAutoFill) private var completeAutoFill
    @LazyInjected(\AutoFillUseCaseContainer.completeTextAutoFill) private var completeTextAutoFill
    @LazyInjected(\AutoFillUseCaseContainer.completePasskeyRegistration) private var completePasskeyRegistration
    @LazyInjected(\UIComponentsContainer.bannerManager) private var bannerManager
    @LazyInjected(\ServiceContainer.upgradeChecker) private var upgradeChecker
    @LazyInjected(\ServiceContainer.appContentManager) private var appContentManager
    @LazyInjected(\UseCasesContainer.getSharedPreferences) private var getSharedPreferences
    @LazyInjected(\UseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching
    @LazyInjected(\ServiceContainer.userManager) private var userManager
    @LazyInjected(\RepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\ToolingContainer.authManager) private var authManager
    @LazyInjected(\UseCasesContainer.logOutAllAccounts) var logOutAllAccounts
    @LazyInjected(\UseCasesContainer.refreshFeatureFlags) var refreshFeatureFlags
    @LazyInjected(\UseCasesContainer.getUserUiModels) var getUserUiModels

    /// Derived properties
    private var lastChildViewController: UIViewController?
    private var currentCreateEditItemViewModel: BaseCreateEditItemViewModel?
    private var credentialsViewModel: CredentialsViewModel?
    private var startTask: Task<Void, Never>?

    private var topMostViewController: UIViewController? {
        rootViewController?.topMostViewController
    }

    private var mode: AutoFillMode?

    init(rootViewController: UIViewController, context: ASCredentialProviderExtensionContext) {
        UIComponentsContainer.shared.register(rootViewController: rootViewController)
        self.rootViewController = rootViewController
        self.context = context

        // Post init
        setUpSentry()
        setCoreLoggerEnvironment()
        setUpRouting()
    }

    deinit {
        startTask?.cancel()
        startTask = nil
        print(deinitMessage)
    }

    /// Necessary set up like initializing preferences and theme before starting user flow
    func setUpAndStart(mode: AutoFillMode) {
        startTask?.cancel()
        startTask = nil
        startTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await setUpBeforeLaunching(rootContainer: .viewController(rootViewController))
                refreshFeatureFlags()
                // This need to be set after user data is loaded as we now depend on active user id to set session
                // to the api service
                authManager.sessionWasInvalidated
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] sessionInfos in
                        guard let self, let userId = sessionInfos.userId else { return }
                        logOut(userId: userId,
                               error: PassError.unexpectedLogout,
                               sessionId: sessionInfos.sessionId)
                    }
                    .store(in: &cancellables)
                try await start(mode: mode)
            } catch {
                handle(error: error)
            }
        }
    }
}

private extension CredentialProviderCoordinator {
    func start(mode: AutoFillMode) async throws {
        let users = try await getUserUiModels()
        self.mode = mode
        switch mode {
        case let .showAllLogins(identifiers, requestParams):
            handleShowAllLoginsMode(mode: .passwords,
                                    users: users,
                                    identifiers: identifiers,
                                    passkeyRequestParams: requestParams)

        case let .checkAndAutoFill(request):
            handleCheckAndAutoFill(request)

        case let .authenticateAndAutofill(request):
            handleAuthenticateAndAutofill(request)

        case .configuration:
            configureExtension()

        case let .passkeyRegistration(request):
            handlePasskeyRegistration(users: users, request: request)

        case let .showOneTimeCodes(identifiers):
            handleShowAllLoginsMode(mode: .oneTimeCodes,
                                    users: users,
                                    identifiers: identifiers,
                                    passkeyRequestParams: nil)

        case .arbitraryTextInsertion:
            handleArbitraryTextInsertion(users: users)
        }
    }

    func handleShowAllLoginsMode(mode: CredentialsMode,
                                 users: [UserUiModel],
                                 identifiers: [ASCredentialServiceIdentifier],
                                 passkeyRequestParams: ASPasskeyCredentialRequestParameters?) {
        guard let context else { return }

        guard userManager.activeUserId != nil else {
            showNotLoggedInView()
            return
        }

        var identifiers = identifiers
        #if DEBUG
        // As of iOS 18.0, the list of service identifiers when autofilling one-time code
        // is always empty even when iOS could detect the OTP form
        // So we mock it for testing purpose
        if identifiers.isEmpty, case .oneTimeCodes = mode {
            identifiers.append(.init(identifier: "https://autofilth.lol", type: .URL))
        }
        #endif

        let viewModel = CredentialsViewModel(mode: mode,
                                             users: users,
                                             serviceIdentifiers: identifiers,
                                             passkeyRequestParams: passkeyRequestParams,
                                             context: context,
                                             userForNewItemSubject: userForNewItemSubject)
        viewModel.delegate = self
        credentialsViewModel = viewModel
        showView(CredentialsView(viewModel: viewModel))

        addNewEvent(type: .autofillDisplay)
        if passkeyRequestParams != nil {
            addNewEvent(type: .passkeyDisplay)
        }
    }

    func handleCheckAndAutoFill(_ request: AutoFillRequest) {
        Task { [weak self] in
            guard let self, let context else { return }
            do {
                guard let recordIdentifier = request.recordIdentifier else {
                    throw ASExtensionError(.credentialIdentityNotFound)
                }

                let ids = try IDs.deserializeBase64(recordIdentifier)
                guard let item = try await itemRepository.getItem(shareId: ids.shareId, itemId: ids.itemId) else {
                    throw ASExtensionError(.credentialIdentityNotFound)
                }

                let prefs = getSharedPreferences()
                try await checkAndAutoFill(request,
                                           userId: item.userId,
                                           context: context,
                                           localAuthenticationMethod: prefs.localAuthenticationMethod,
                                           appLockTime: prefs.appLockTime,
                                           lastActiveTimestamp: prefs.lastActiveTimestamp)
            } catch {
                logger.error(error)
                cancelAutoFill(reason: .failed, context: context)
            }
        }
    }

    func handleAuthenticateAndAutofill(_ request: AutoFillRequest) {
        let viewModel = LockedCredentialViewModel(request: request) { [weak self] result in
            guard let self, let context else { return }
            switch result {
            case let .success((credential, itemContent)):
                Task { [weak self] in
                    guard let self else { return }
                    try? await completeAutoFill(quickTypeBar: false,
                                                identifiers: request.serviceIdentifiers,
                                                credential: credential,
                                                itemContent: itemContent,
                                                context: context)
                }

            case let .failure(error):
                handle(error: error)
            }
        }
        showView(LockedCredentialView(viewModel: viewModel))
    }

    func handlePasskeyRegistration(users: [UserUiModel],
                                   request: PasskeyCredentialRequest) {
        guard let context else { return }
        let viewModel = PasskeyCredentialsViewModel(users: users,
                                                    request: request,
                                                    context: context,
                                                    userForNewItemSubject: userForNewItemSubject)
        viewModel.delegate = self
        let view = PasskeyCredentialsView(viewModel: viewModel)
        showView(view)
    }

    func handleArbitraryTextInsertion(users: [UserUiModel]) {
        guard let context else { return }
        let viewModel = ItemsForTextInsertionViewModel(context: context,
                                                       users: users,
                                                       userForNewItemSubject: userForNewItemSubject)
        viewModel.delegate = self
        showView(ItemsForTextInsertionView(viewModel: viewModel))
    }
}

private extension CredentialProviderCoordinator {
    func configureExtension() {
        guard let context else { return }
        guard let activeUserId = userManager.activeUserId else {
            showNotLoggedInView()
            return
        }

        let view = ExtensionSettingsView(onDismiss: { [weak self] in
            guard let self else { return }
            completeConfiguration(context: context)
        }, onLogOut: { [weak self] _ in
            guard let self else { return }
            logOut(userId: activeUserId) { [weak self] in
                guard let self else { return }
                completeConfiguration(context: context)
            }
        })
        showView(view)
    }
}

extension CredentialProviderCoordinator: ExtensionCoordinator {
    func getRootViewController() -> UIViewController? {
        rootViewController
    }

    func getLastChildViewController() -> UIViewController? {
        lastChildViewController
    }

    func setLastChildViewController(_ viewController: UIViewController) {
        lastChildViewController = viewController
    }
}

// MARK: - Setup & Utils

private extension CredentialProviderCoordinator {
    func setUpRouting() {
        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case .upgradeFlow:
                    startUpgradeFlow()

                case let .createItem(item, type, _, response):
                    handleItemCreation(item, type: type, response: response)

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

                case let .errorMessage(message):
                    bannerManager.displayTopErrorMessage(message)

                default:
                    return
                }
            }
            .store(in: &cancellables)
    }

    func presentSelectUserActionSheet(_ users: [UserUiModel]) {
        let alert = UIAlertController(title: #localized("Select account"),
                                      message: nil,
                                      preferredStyle: UIDevice.current.isIpad ? .alert : .actionSheet)
        for user in users {
            alert.addAction(.init(title: user.email ?? user.displayName ?? "?",
                                  style: .default,
                                  handler: { [weak self] _ in
                                      guard let self else { return }
                                      userForNewItemSubject.send(user)
                                  }))
        }

        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        present(alert)
    }

    // swiftlint:disable:next cyclomatic_complexity
    func handle(error: any Error,
                file: String = #file,
                function: String = #function,
                line: UInt = #line,
                column: UInt = #column) {
        guard let context else { return }
        let defaultHandler: (any Error) -> Void = { [weak self] error in
            guard let self else { return }
            logger.error(error, file: file, function: function, line: line, column: column)
            alert(error: error) { [weak self] in
                guard let self else { return }
                cancelAutoFill(reason: .failed, context: context)
            }
        }

        if let error = error as? PassError,
           case let .userManager(reason) = error {
            switch reason {
            case .noUserDataFound:
                showNotLoggedInView()
                return

            default:
                defaultHandler(error)
                return
            }
        }

        guard let error = error as? PassError,
              case let .credentialProvider(reason) = error else {
            defaultHandler(error)
            return
        }

        switch reason {
        case .userCancelled:
            cancelAutoFill(reason: .userCanceled, context: context)
            return

        case .failedToAuthenticate:
            guard let userId = userManager.activeUserId else {
                defaultHandler(error)
                return
            }
            logOut(userId: userId) { [weak self] in
                guard let self else { return }
                // swiftlint:disable:next todo
                // TODO: should we always call the cancelAutoFill as we will be able to have multiple account for one user
                // this means we should in some case only reload the data to remove the deleted content.
                cancelAutoFill(reason: .failed, context: context)
            }
            return

        default:
            defaultHandler(error)
        }
    }

    func addNewEvent(type: TelemetryEventType) {
        addTelemetryEvent(with: type)
    }

    func logOut(userId: String,
                error: (any Error)? = nil,
                sessionId: String? = nil,
                completion: (() -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            if let error {
                sendErrorToSentry(error, userId: userId, sessionId: sessionId)
            }

            do {
                try await logOutAllAccounts()
                showNotLoggedInView()
            } catch {
                logger.error(error)
            }
            completion?()
        }
    }
}

// MARK: - Views for routing

private extension CredentialProviderCoordinator {
    func showNotLoggedInView() {
        guard let context else { return }
        let view = NotLoggedInView(variant: .autoFillExtension) { [weak self] in
            guard let self else { return }
            cancelAutoFill(reason: .userCanceled, context: context)
        }
        showView(view)
    }

    func presentCreateLoginView(url: URL?,
                                request: PasskeyCredentialRequest?) {
        do {
            let creationType = ItemCreationType.login(title: url?.host,
                                                      url: url?.schemeAndHost,
                                                      autofill: true,
                                                      passkeyCredentialRequest: request)
            let viewModel = try CreateEditLoginViewModel(mode: .create(creationType),
                                                         upgradeChecker: upgradeChecker)
            viewModel.delegate = self
            present(CreateEditLoginView(viewModel: viewModel), dismissBeforePresenting: true)
            currentCreateEditItemViewModel = viewModel
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func presentCreateAliasView() {
        do {
            let viewModel = try CreateEditAliasViewModel(mode: .create(.alias),
                                                         upgradeChecker: upgradeChecker)
            present(CreateEditAliasView(viewModel: viewModel), dismissBeforePresenting: true)
            currentCreateEditItemViewModel = viewModel
        } catch {
            logger.error(error)
            bannerManager.displayTopErrorMessage(error)
        }
    }

    func handleCreatedItem(_ itemContentType: ItemContentType) {
        topMostViewController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            bannerManager.displayBottomSuccessMessage(itemContentType.creationMessage)
        }
    }

    func present(_ view: some View, dismissBeforePresenting: Bool) {
        let viewController = UIHostingController(rootView: view)
        present(viewController, dismissBeforePresenting: dismissBeforePresenting)
    }

    func present(_ viewController: UIViewController,
                 animated: Bool = true,
                 dismissible: Bool = false,
                 dismissBeforePresenting: Bool = false) {
        viewController.isModalInPresentation = !dismissible
        viewController.overrideUserInterfaceStyle = rootViewController?
            .overrideUserInterfaceStyle ?? .unspecified
        if dismissBeforePresenting {
            rootViewController?.topMostViewController.dismiss(animated: animated) { [weak self] in
                guard let self else { return }
                rootViewController?.topMostViewController.present(viewController,
                                                                  animated: animated)
            }
        } else {
            topMostViewController?.present(viewController, animated: animated)
        }
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

extension CredentialProviderCoordinator {
    func handleItemCreation(_ item: SymmetricallyEncryptedItem,
                            type: ItemContentType,
                            response: CreatePasskeyResponse?) {
        switch type {
        case .login:
            Task { [weak self] in
                guard let self, let context else { return }
                do {
                    if getSharedPreferences().quickTypeBar {
                        try await indexAllLoginItems()
                    }
                    if let response {
                        completePasskeyRegistration(response, context: context)
                    } else if mode?.isArbitraryTextInsertion == true {
                        let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                                  itemId: item.itemId)
                        try await completeTextAutoFill(itemContent?.loginItem?.authIdentifier ?? "",
                                                       context: context,
                                                       userId: nil,
                                                       item: item)
                    } else {
                        credentialsViewModel?.select(item: item)
                    }
                } catch {
                    logger.error(error)
                }
            }

        case .alias:
            Task { [weak self] in
                guard let self,
                      let context,
                      mode?.isArbitraryTextInsertion == true,
                      let email = item.item.aliasEmail else { return }
                do {
                    try await completeTextAutoFill(email,
                                                   context: context,
                                                   userId: nil,
                                                   item: item)
                } catch {
                    logger.error(error)
                }
            }

        default:
            handleCreatedItem(type)
        }
        addNewEvent(type: .create(type))
    }
}

// MARK: - CreateEditLoginViewModelDelegate

extension CredentialProviderCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: any AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController, dismissible: true)
    }
}

extension CredentialProviderCoordinator: AutoFillViewModelDelegate {
    func autoFillViewModelWantsToCreateNewItem(_ info: ItemCreationInfo) {
        Task { [weak self] in
            guard let self else { return }
            do {
                // Temporarily switch the on-memory active user and reload the vaults contents
                // This is to work-around the fact that many of our repositories, use cases, view models
                // still depend on the active user instead of dynamically take a userID
                // especially when creating new login items we need to check some limitations
                // (login with 2FA, custom fields...)
                try await userManager.switchActiveUser(with: info.userId, onMemory: true)
                await appContentManager.refresh(userId: info.userId)

                switch info.data {
                case let .login(url, passkeyCredentialRequest):
                    presentCreateLoginView(url: url,
                                           request: passkeyCredentialRequest)

                case .alias:
                    presentCreateAliasView()
                }
            } catch {
                logger.error(error)
                bannerManager.displayTopErrorMessage(error)
            }
        }
    }

    func autoFillViewModelWantsToSelectUser(_ users: [Entities.UserUiModel]) {
        presentSelectUserActionSheet(users)
    }

    func autoFillViewModelWantsToCancel() {
        if let context {
            cancelAutoFill(reason: .userCanceled, context: context)
        } else {
            assertionFailure("AutoFill context should not be nil")
        }
    }

    func autoFillViewModelWantsToLogOut() {
        guard let userId = userManager.activeUserId else { return }
        logOut(userId: userId)
    }
}
