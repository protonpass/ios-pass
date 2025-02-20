//
// ActionCoordinator.swift
// Proton Pass - Created on 09/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Combine
import DesignSystem
import Entities
import Factory
import Screens
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ActionCoordinator {
    @LazyInjected(\SharedDataContainer.credentialProvider) private var credentialProvider
    @LazyInjected(\SharedUseCasesContainer.setUpSentry) private var setUpSentry
    @LazyInjected(\SharedUseCasesContainer.setCoreLoggerEnvironment) private var setCoreLoggerEnvironment
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedUseCasesContainer.sendErrorToSentry) private var sendErrorToSentry
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedToolingContainer.logManager) private var logManager
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedUseCasesContainer.setUpBeforeLaunching) private var setUpBeforeLaunching
    @LazyInjected(\SharedUseCasesContainer.getSharedPreferences) private var getSharedPreferences
    @LazyInjected(\SharedUseCasesContainer.logOutAllAccounts) private var logOutAllAccounts
    @LazyInjected(\SharedUseCasesContainer.getUserUiModels) private var getUserUiModels
    @LazyInjected(\SharedUseCasesContainer.parseCsvLogins) private var parseCsvLogins
    @LazyInjected(\SharedUseCasesContainer.createVaultAndImportLogins)
    private var createVaultAndImportLogins

    private var lastChildViewController: UIViewController?
    private weak var rootViewController: UIViewController?
    private var context: NSExtensionContext? { rootViewController?.extensionContext }

    private var cancellables = Set<AnyCancellable>()

    init(rootViewController: UIViewController?) {
        self.rootViewController = rootViewController
        AppearanceSettings.apply()
        setUpSentry()
        setUpRouter()
        setCoreLoggerEnvironment()
    }
}

// MARK: Public APIs

extension ActionCoordinator {
    func start() async {
        do {
            try await setUpBeforeLaunching(rootContainer: .viewController(rootViewController))
            guard getFeatureFlagStatus(for: FeatureFlagType.passIOSImportCsv) else {
                dismissExtension()
                return
            }
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

private extension ActionCoordinator {
    func setUpRouter() {
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
                default:
                    return
                }
            }
            .store(in: &cancellables)
    }

    func beginFlow() async {
        if let activeUserId = userManager.activeUserId,
           credentialProvider.isAuthenticated(userId: activeUserId) {
            let prefs = getSharedPreferences()
            let view = ImporterView(logManager: logManager,
                                    datasource: self,
                                    onClose: { [weak self] in
                                        guard let self else { return }
                                        dismissExtension()
                                    })
                                    .if(prefs.localAuthenticationMethod == .pin) { view in
                                        // Only request for local authencation when it's PIN
                                        // to workaround iOS bug which dismisses the extension after doing
                                        // Face ID or Touch ID authentication
                                        // Steps to reproduce:
                                        // 1. Enable biometric authentication system wide and app wide
                                        // 2. Open Chrome and export passwords
                                        // 3. Select "Import to Proton Pass"
                                        // => bug
                                        // Only occurs when importing on the fly after exporting from Chrome
                                        // Works fine when sharing an exported CSV
                                        view.localAuthentication(onFailure: { [weak self] _ in
                                            guard let self else { return }
                                            logOut(userId: activeUserId)
                                        })
                                    }

            showView(view)
        } else {
            showNotLoggedInView()
        }
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

    func dismissExtension() {
        context?.completeRequest(returningItems: nil)
    }

    func showNotLoggedInView() {
        let view = NotLoggedInView(variant: .actionExtension) { [weak self] in
            guard let self else { return }
            dismissExtension()
        }
        showView(view)
    }
}

// MARK: ExtensionCoordinator

extension ActionCoordinator: ExtensionCoordinator {
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

extension ActionCoordinator: ImporterDatasource {
    func getUsers() async throws -> [UserUiModel] {
        try await getUserUiModels()
    }

    func parseLogins() async throws -> [CsvLogin] {
        guard let items = context?.inputItems as? [NSExtensionItem] else {
            throw PassError.extension(.noInputItems)
        }

        var csvString: String?
        for item in items {
            guard let attachments = item.attachments else {
                throw PassError.extension(.noAttachments)
            }

            let id = UTType.commaSeparatedText.identifier

            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(id),
                   let url = try await provider.loadItem(forTypeIdentifier: id) as? URL {
                    let data = try Data(contentsOf: url)
                    csvString = String(data: data, encoding: .utf8)
                }
            }
        }

        guard let csvString else {
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
