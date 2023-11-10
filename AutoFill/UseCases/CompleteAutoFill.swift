//
// CompleteAutoFill.swift
// Proton Pass - Created on 31/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import UseCases

protocol CompleteAutoFillUseCase: Sendable {
    func execute(quickTypeBar: Bool,
                 credential: ASPasswordCredential,
                 itemContent: ItemContent,
                 upgradeChecker: UpgradeCheckerProtocol,
                 telemetryEventRepository: TelemetryEventRepositoryProtocol?) async throws
}

extension CompleteAutoFillUseCase {
    func callAsFunction(quickTypeBar: Bool,
                        credential: ASPasswordCredential,
                        itemContent: ItemContent,
                        upgradeChecker: UpgradeCheckerProtocol,
                        telemetryEventRepository: TelemetryEventRepositoryProtocol?) async throws {
        try await execute(quickTypeBar: quickTypeBar,
                          credential: credential,
                          itemContent: itemContent,
                          upgradeChecker: upgradeChecker,
                          telemetryEventRepository: telemetryEventRepository)
    }
}

final class CompleteAutoFill: @unchecked Sendable, CompleteAutoFillUseCase {
    private let context: ASCredentialProviderExtensionContext
    private let logger: Logger
    private let logManager: LogManagerProtocol
    private let appVersion: String
    private let userDataProvider: UserDataProvider
    private let clipboardManager: ClipboardManager
    private let copyTotpTokenAndNotify: CopyTotpTokenAndNotifyUseCase
    private let updateLastUseTime: UpdateLastUseTimeUseCase
    private let databaseService: DatabaseServiceProtocol
    private let resetFactory: ResetFactoryUseCase

    init(context: ASCredentialProviderExtensionContext,
         logManager: LogManagerProtocol,
         appVersion: String,
         userDataProvider: UserDataProvider,
         clipboardManager: ClipboardManager,
         copyTotpTokenAndNotify: CopyTotpTokenAndNotifyUseCase,
         updateLastUseTime: UpdateLastUseTimeUseCase,
         databaseService: DatabaseServiceProtocol,
         resetFactory: ResetFactoryUseCase) {
        self.context = context
        logger = .init(manager: logManager)
        self.logManager = logManager
        self.appVersion = appVersion
        self.userDataProvider = userDataProvider
        self.clipboardManager = clipboardManager
        self.copyTotpTokenAndNotify = copyTotpTokenAndNotify
        self.updateLastUseTime = updateLastUseTime
        self.databaseService = databaseService
        self.resetFactory = resetFactory
    }

    /*
     Complete the autofill process by updating item's `lastUseTime` and reindex all login items
     While these processes can eventually fails, we don't really do anything when errors happen but only log them.
     Because they all happen in the completion block of the `completeRequest` of `ASCredentialProviderExtensionContext`
     and at this moment the autofill process is done and the extension is already closed, we have no way to tell users about the errors anyway
     */
    func execute(quickTypeBar: Bool,
                 credential: ASPasswordCredential,
                 itemContent: ItemContent,
                 upgradeChecker: UpgradeCheckerProtocol,
                 telemetryEventRepository: TelemetryEventRepositoryProtocol?) async throws {
        do {
            if quickTypeBar {
                try await telemetryEventRepository?.addNewEvent(type: .autofillTriggeredFromSource)
            } else {
                try await telemetryEventRepository?.addNewEvent(type: .autofillTriggeredFromApp)
            }
            logger
                .info("Autofilled from QuickType bar \(quickTypeBar) \(itemContent.debugDescription)")
            if Task.isCancelled {
                resetFactory()
            }
            await logManager.saveAllLogs()
            try await copyTotpTokenAndNotify(itemContent: itemContent,
                                             clipboardManager: clipboardManager,
                                             upgradeChecker: upgradeChecker)
            context.completeRequest(withSelectedCredential: credential) { [weak self] _ in
                guard let self else { return }
                updateLastUseTime(item: itemContent)
            }
        } catch {
            // Do nothing but only log the errors
            logger.error(error)
            // Repeat the "saveAllLogs" function instead of deferring
            // because we can't "await" in defer block
            await logManager.saveAllLogs()
        }
    }
}

private extension CompleteAutoFill {
    func updateLastUseTime(item: ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            defer { resetFactory() }
            do {
                let credential = try userDataProvider.getUnwrappedUserData().credential
                let doh = ProtonPassDoH()
                let baseUrl = doh.defaultHost + doh.defaultPath
                let result = try await updateLastUseTime(baseUrl: baseUrl,
                                                         sessionId: credential.sessionID,
                                                         accessToken: credential.accessToken,
                                                         appVersion: appVersion,
                                                         item: item,
                                                         date: .now)
                switch result {
                case .successful:
                    logger.info("Updated lastUseTime \(item.debugDescription)")
                case .shouldRefreshAccessToken:
                    logger.info("TODO: refresh access token")
                case .shouldLogOut:
                    logger
                        .error("Token is expired while updating lastUseTime \(item.debugDescription). Logging out.")
                    userDataProvider.setUserData(nil)
                    databaseService.resetContainer()
                    // Unindex all items also
                }
            } catch {
                logger.error(error)
            }
        }
    }
}
