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
    private let clipboardManager: ClipboardManager
    private let copyTotpTokenAndNotify: CopyTotpTokenAndNotifyUseCase
    private let resetFactory: ResetFactoryUseCase
    private let itemRepository: ItemRepositoryProtocol

    init(context: ASCredentialProviderExtensionContext,
         logManager: LogManagerProtocol,
         clipboardManager: ClipboardManager,
         itemRepository: ItemRepositoryProtocol,
         copyTotpTokenAndNotify: CopyTotpTokenAndNotifyUseCase,
         resetFactory: ResetFactoryUseCase) {
        self.context = context
        logger = .init(manager: logManager)
        self.logManager = logManager
        self.itemRepository = itemRepository
        self.clipboardManager = clipboardManager
        self.copyTotpTokenAndNotify = copyTotpTokenAndNotify
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
        defer {
            resetFactory()
        }
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
            try await update(itemContent: itemContent)

            await context.completeRequestAsync(credential: credential)
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
    func update(itemContent: ItemContent) async throws {
        logger.trace("Updating lastUseTime \(itemContent.debugDescription)")
        try await itemRepository.saveLocally(lastUseTime: Date().timeIntervalSince1970, for: itemContent)
        logger.info("Updated lastUseTime \(itemContent.debugDescription)")
    }
}

private extension ASCredentialProviderExtensionContext {
    @discardableResult
    func completeRequestAsync(credential: ASPasswordCredential) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            completeRequest(withSelectedCredential: credential) { result in
                continuation.resume(returning: result)
            }
        }
    }
}
