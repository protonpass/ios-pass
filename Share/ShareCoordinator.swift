//
// ShareCoordinator.swift
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

import Client
@preconcurrency import Combine
import Core
import DesignSystem
import Entities
import FactoryKit
@preconcurrency import Foundation
import Macro
import Screens
@preconcurrency import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum SharedContent: Sendable {
    case url(URL)
    case text(String)
    case textWithUrl(String, URL)
    case csv(Data)
    case unknown

    var url: URL? {
        switch self {
        case let .url(url): url
        case let .textWithUrl(_, url): url
        default: nil
        }
    }

    var note: String {
        switch self {
        case let .url(url): url.absoluteString
        case let .text(text): text
        case let .textWithUrl(text, _): text
        default: ""
        }
    }

    func title(for type: SharedItemType) -> String {
        guard case let .url(url) = self else { return "" }
        let urlString = url.absoluteString
        return switch type {
        case .note: #localized("Note for %@", urlString)
        case .login: #localized("Login for %@", urlString)
        }
    }
}

enum SharedItemType: CaseIterable {
    case note, login
}

@MainActor
final class ShareCoordinator {
    private let credentialProvider = resolve(\SharedDataContainer.credentialProvider)
    private let setUpSentry = resolve(\SharedUseCasesContainer.setUpSentry)
    private let setCoreLoggerEnvironment = resolve(\SharedUseCasesContainer.setCoreLoggerEnvironment)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let sendErrorToSentry = resolve(\SharedUseCasesContainer.sendErrorToSentry)

    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedServiceContainer.appContentManager) private var appContentManager
    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    @LazyInjected(\SharedUseCasesContainer.logOutAllAccounts) private var logOutAllAccounts
    @LazyInjected(\SharedServiceContainer.upgradeChecker) private var upgradeChecker
    @LazyInjected(\SharedViewContainer.bannerManager) private var bannerManager
    @LazyInjected(\SharedUseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.authManager) private var authManager
    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager
    @LazyInjected(\SharedToolingContainer.logManager) private var logManager
    @LazyInjected(\SharedUseCasesContainer.getUserUiModels) private var getUserUiModels
    @LazyInjected(\SharedUseCasesContainer.parseCsvLogins) private var parseCsvLogins
    @LazyInjected(\SharedUseCasesContainer.createVaultAndImportLogins)
    private var createVaultAndImportLogins

    private var lastChildViewController: UIViewController?
    private weak var rootViewController: UIViewController?
    private var createEditItemViewModel: BaseCreateEditItemViewModel?
    private var generatePasswordCoordinator: GeneratePasswordCoordinator?

    private var parsedContent: SharedContent?
    private var cancellables = Set<AnyCancellable>()

    private var context: NSExtensionContext? { rootViewController?.extensionContext }
    private var topMostViewController: UIViewController? { rootViewController?.topMostViewController }

    init(rootViewController: UIViewController) {
        SharedViewContainer.shared.register(rootViewController: rootViewController)
        self.rootViewController = rootViewController
        AppearanceSettings.apply()
        setUpSentry()
        setUpRouter()
        setCoreLoggerEnvironment()

        authManager.sessionWasInvalidated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionInfos in
                guard let self, let userId = sessionInfos.userId else { return }
                logOut(userId: userId,
                       error: PassError.unexpectedLogout,
                       sessionId: sessionInfos.sessionId)
            }
            .store(in: &cancellables)
    }
}

// MARK: Public APIs

extension ShareCoordinator {
    func start() async {
        do {
            try await setUpBeforeLaunching(rootContainer: .viewController(rootViewController))
            await beginFlow()
        } catch {
            alert(error: error) { [weak self] in
                guard let self else { return }
                dismissExtension()
            }
        }
    }
}

// MARK: Private APIs

private extension ShareCoordinator {
    func setUpRouter() {
        router
            .newSheetDestination
            .receive(on: DispatchQueue.main)
            .sink { [weak self] destination in
                guard let self else { return }
                switch destination {
                case let .createItem(_, type, _):
                    handleItemCreation(type: type)
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

    func showNotLoggedInView() {
        let view = NotLoggedInView(variant: .shareExtension) { [weak self] in
            guard let self else { return }
            dismissExtension()
        }
        showView(view)
    }

    func parseSharedContent() async throws -> SharedContent {
        guard let extensionItems = context?.inputItems as? [NSExtensionItem] else {
            assertionFailure("Failed to cast inputItems into NSExtensionItems")
            return .unknown
        }

        let parseUrl: (URL, SharedContent) -> SharedContent = { url, fallback in
            guard url.absoluteString.hasPrefix("file://"),
                  url.absoluteString.hasSuffix(".csv"),
                  let data = try? Data(contentsOf: url) else { return fallback }
            return .csv(data)
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for attachment in attachments {
                if let url = await Task(operation: { @Sendable in
                    try? await attachment.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL
                }).value {
                    return parseUrl(url, .url(url))
                }

                if let text = await Task(operation: { @Sendable in
                    try? await attachment
                        .loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String
                }).value {
                    if let url = text.firstUrl() {
                        return parseUrl(url, .textWithUrl(text, url))
                    } else {
                        return .text(text)
                    }
                }
            }
        }

        return .unknown
    }

    func parseSharedContentAndBeginShareFlow(userId: String) async {
        do {
            let content = try await parseSharedContent()
            parsedContent = content

            let view: any View
            if case .csv = content,
               let activeUserId = userManager.activeUserId {
                let prefs = preferencesManager.sharedPreferences.unwrapped()
                view = ImporterView(logManager: logManager,
                                    datasource: self,
                                    onClose: { [weak self] in
                                        guard let self else { return }
                                        dismissExtension()
                                    })
                                    .if(prefs.localAuthenticationMethod == .pin) { view in
                                        view.localAuthentication(onFailure: { [weak self] _ in
                                            guard let self else { return }
                                            logOut(userId: activeUserId)
                                        })
                                    }
            } else {
                view = SharedContentView(content: content,
                                         onCreate: { [weak self] type in
                                             guard let self else { return }
                                             presentCreateItemView(for: type, content: content)
                                         },
                                         onDismiss: { [weak self] in
                                             guard let self else { return }
                                             dismissExtension()
                                         })
                                         .localAuthentication(onFailure: { [weak self] _ in
                                             guard let self else { return }
                                             logOut(userId: userId)
                                         })
            }

            showView(view)
        } catch {
            alert(error: error) { [weak self] in
                guard let self else { return }
                dismissExtension()
            }
        }
    }

    func presentCreateItemView(for type: SharedItemType, content: SharedContent) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                if appContentManager.getAllSharesContent().isEmpty {
                    try await appContentManager.refresh(userId: userId)
                }
                let shareId = await getMainVault()?.shareId ?? ""
                let vaults = appContentManager.getAllShares()
                let title = content.title(for: type)

                let viewController: UIViewController
                switch type {
                case .note:
                    let creationType = ItemCreationType.note(title: title, note: content.note)
                    let viewModel = try CreateEditNoteViewModel(mode: .create(shareId: shareId,
                                                                              type: creationType),
                                                                upgradeChecker: upgradeChecker,
                                                                vaults: vaults)
                    createEditItemViewModel = viewModel
                    let view = CreateEditNoteView(viewModel: viewModel)
                    viewController = UIHostingController(rootView: view)
                case .login:
                    let urlString = content.url?.absoluteString
                    let creationType = ItemCreationType.login(title: title,
                                                              url: urlString,
                                                              note: content.note,
                                                              autofill: false)
                    let viewModel =
                        try CreateEditLoginViewModel(mode: .create(shareId: shareId, type: creationType),
                                                     upgradeChecker: upgradeChecker, vaults: vaults)
                    viewModel.delegate = self
                    createEditItemViewModel = viewModel
                    let view = CreateEditLoginView(viewModel: viewModel)
                    viewController = UIHostingController(rootView: view)
                }
                present(viewController)
            } catch {
                alert(error: error) { [weak self] in
                    guard let self else { return }
                    dismissExtension()
                }
            }
        }
    }

    func dismissExtension() {
        context?.completeRequest(returningItems: nil)
    }

    func logOut(userId: String,
                error: (any Error)? = nil,
                sessionId: String? = nil) {
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
        }
    }

    func beginFlow() async {
        if let activeUserId = userManager.activeUserId,
           credentialProvider.isAuthenticated(userId: activeUserId) {
            await parseSharedContentAndBeginShareFlow(userId: activeUserId)
        } else {
            showNotLoggedInView()
        }
    }

    func present(_ viewController: UIViewController, animated: Bool = true) {
        let theme = preferencesManager.sharedPreferences.unwrapped().theme
        viewController.overrideUserInterfaceStyle = theme.userInterfaceStyle
        topMostViewController?.present(viewController, animated: animated)
    }
}

// MARK: ExtensionCoordinator

extension ShareCoordinator: ExtensionCoordinator {
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

extension ShareCoordinator {
    func handleItemCreation(type: ItemContentType) {
        let alert = UIAlertController(title: type.creationMessage, message: nil, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: #localized("Close"), style: .default) { [weak self] _ in
            guard let self else { return }
            dismissExtension()
        }
        alert.addAction(closeAction)
        present(alert)
    }
}

// MARK: CreateEditLoginViewModelDelegate

extension ShareCoordinator: CreateEditLoginViewModelDelegate {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: any AliasCreationLiteInfoDelegate) {
        let viewModel = CreateAliasLiteViewModel(options: options, creationInfo: creationInfo)
        viewModel.aliasCreationDelegate = delegate
        let view = CreateAliasLiteView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.detents = [.medium()]
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        present(viewController)
    }

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: any GeneratePasswordViewModelDelegate) {
        let coordinator = GeneratePasswordCoordinator(generatePasswordViewModelDelegate: delegate,
                                                      mode: .createLogin)
        coordinator.delegate = self
        coordinator.start()
        generatePasswordCoordinator = coordinator
    }
}

// MARK: GeneratePasswordCoordinatorDelegate

extension ShareCoordinator: GeneratePasswordCoordinatorDelegate {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController) {
        present(viewController)
    }
}

// MARK: ImporterDatasource

extension ShareCoordinator: ImporterDatasource {
    func getUsers() async throws -> [UserUiModel] {
        try await getUserUiModels()
    }

    func parseLogins() async throws -> [CsvLogin] {
        guard case let .csv(data) = parsedContent,
              let csvString = String(data: data, encoding: .utf8) else {
            throw PassError.importer(.noCsvContent)
        }

        return try await parseCsvLogins(csvString)
    }

    func proceedImportation(user: UserUiModel?, logins: [CsvLogin]) async throws {
        let userId: String = if let user {
            user.id
        } else {
            try await userManager.getActiveUserId()
        }
        try await createVaultAndImportLogins(userId: userId, logins: logins)
    }
}
