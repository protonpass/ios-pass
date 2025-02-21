//
// CredentialManager.swift
// Proton Pass - Created on 04/10/2022.
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
import Core
import Entities

public protocol CredentialManagerProtocol: Sendable {
    /// Whether users had choosen Proton Pass as AutoFill Provider
    var isAutoFillEnabled: Bool { get async }

    func remove(credentials: [CredentialIdentity]) async throws
    func insert(credentials: [CredentialIdentity]) async throws
    func removeAllCredentials() async throws
    @available(iOS 18, *)
    func enableAutoFill() async -> Bool
}

public final class CredentialManager: CredentialManagerProtocol {
    private let store: ASCredentialIdentityStore
    private let logger: Logger

    public init(logManager: any LogManagerProtocol,
                store: ASCredentialIdentityStore = .shared) {
        self.store = store
        logger = .init(manager: logManager)
    }
}

public extension CredentialManager {
    var isAutoFillEnabled: Bool {
        get async {
            await store.state().isEnabled
        }
    }

    func remove(credentials: [CredentialIdentity]) async throws {
        logger.trace("Trying to remove \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing \(credentials.count) credentials.")
            return
        }

        if state.supportsIncrementalUpdates {
            logger.trace("Non empty credential store. Removing \(credentials.count) credentials.")
            try await store.performAction(.remove, on: credentials)
        } else {
            logger.trace("Empty credential store. Nothing to remove.")
        }
    }

    func insert(credentials: [CredentialIdentity]) async throws {
        logger.trace("Trying to insert \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped inserting \(credentials.count) credentials.")
            return
        }

        if state.supportsIncrementalUpdates {
            logger.trace("Non empty credential store. Inserting \(credentials.count) credentials.")
            try await store.performAction(.save, on: credentials)
        } else {
            logger.trace("Empty credential store. Inserting \(credentials.count) credentials.")
            try await store.performAction(.replace, on: credentials)
        }
        logger.trace("Inserted \(credentials.count) credentials.")
    }

    func removeAllCredentials() async throws {
        logger.trace("Removing all credentials.")
        guard await isAutoFillEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing all credentials.")
            return
        }
        try await store.removeAllCredentialIdentities()
        logger.trace("Removed all credentials.")
    }

    @available(iOS 18, *)
    func enableAutoFill() async -> Bool {
        await ASSettingsHelper.requestToTurnOnCredentialProviderExtension()
    }
}
