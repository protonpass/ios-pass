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

@preconcurrency import AuthenticationServices
import Client
import Core
import Entities
import UseCases

protocol CompleteAutoFillUseCase: Sendable {
    func execute(quickTypeBar: Bool,
                 identifiers: [ASCredentialServiceIdentifier],
                 credential: any ASAuthorizationCredential,
                 itemContent: ItemContent,
                 context: ASCredentialProviderExtensionContext) async throws
}

extension CompleteAutoFillUseCase {
    func callAsFunction(quickTypeBar: Bool,
                        identifiers: [ASCredentialServiceIdentifier],
                        credential: any ASAuthorizationCredential,
                        itemContent: ItemContent,
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(quickTypeBar: quickTypeBar,
                          identifiers: identifiers,
                          credential: credential,
                          itemContent: itemContent,
                          context: context)
    }
}

final class CompleteAutoFill: @unchecked Sendable, CompleteAutoFillUseCase {
    private let logger: Logger
    private let logManager: any LogManagerProtocol
    private let telemetryRepository: any TelemetryEventRepositoryProtocol
    private let copyTotpTokenAndNotify: any CopyTotpTokenAndNotifyUseCase
    private let updateLastUseTimeAndReindex: any UpdateLastUseTimeAndReindexUseCase
    private let resetFactory: any ResetFactoryUseCase
    private let userManager: any UserManagerProtocol

    init(logManager: any LogManagerProtocol,
         telemetryRepository: any TelemetryEventRepositoryProtocol,
         userManager: any UserManagerProtocol,
         copyTotpTokenAndNotify: any CopyTotpTokenAndNotifyUseCase,
         updateLastUseTimeAndReindex: any UpdateLastUseTimeAndReindexUseCase,
         resetFactory: any ResetFactoryUseCase) {
        logger = .init(manager: logManager)
        self.logManager = logManager
        self.telemetryRepository = telemetryRepository
        self.copyTotpTokenAndNotify = copyTotpTokenAndNotify
        self.updateLastUseTimeAndReindex = updateLastUseTimeAndReindex
        self.resetFactory = resetFactory
        self.userManager = userManager
    }

    /*
     Complete the autofill process by updating item's `lastUseTime` and reindex all login items
     While these processes can eventually fails, we don't really do anything when errors happen but only log them.
     Because they all happen in the completion block of the `completeRequest` of `ASCredentialProviderExtensionContext`
     and at this moment the autofill process is done and the extension is already closed, we have no way to tell users about the errors anyway
     */
    func execute(quickTypeBar: Bool,
                 identifiers: [ASCredentialServiceIdentifier],
                 credential: any ASAuthorizationCredential,
                 itemContent: ItemContent,
                 context: ASCredentialProviderExtensionContext) async throws {
        defer {
            resetFactory()
        }
        do {
            let userId = try await userManager.getActiveUserId()
            if quickTypeBar {
                try await telemetryRepository.addNewEvent(userId: userId,
                                                          type: .autofillTriggeredFromSource)
            } else {
                try await telemetryRepository.addNewEvent(userId: userId,
                                                          type: .autofillTriggeredFromApp)
            }
            logger
                .info("Autofilled from QuickType bar \(quickTypeBar) \(itemContent.debugDescription)")
            if Task.isCancelled {
                resetFactory()
            }
            await logManager.saveAllLogs()
            try await copyTotpTokenAndNotify(itemContent: itemContent)
            let completion: @Sendable (Bool) -> Void = { [weak self] _ in
                guard let self else { return }
                update(item: itemContent, identifiers: identifiers)
            }

            if let passwordCredential = credential as? ASPasswordCredential {
                context.completeRequest(withSelectedCredential: passwordCredential,
                                        completionHandler: completion)
            } else if #available(iOS 17, *),
                      let passkeyCredential = credential as? ASPasskeyAssertionCredential {
                try await telemetryRepository.addNewEvent(userId: userId, type: .passkeyAuth)
                context.completeAssertionRequest(using: passkeyCredential,
                                                 completionHandler: completion)
            } else if #available(iOS 18, *),
                      let oneTimeCodeCredential = credential as? ASOneTimeCodeCredential {
                await context.completeOneTimeCodeRequest(using: oneTimeCodeCredential)
            } else {
                assertionFailure("Unsupported credential")
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
    func update(item: ItemContent, identifiers: [ASCredentialServiceIdentifier]) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await updateLastUseTimeAndReindex(item: item,
                                                      date: .now,
                                                      identifiers: identifiers)
                await logManager.saveAllLogs()
            } catch {
                logger.error(error)
                await logManager.saveAllLogs()
            }
        }
    }
}
