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

public protocol CredentialManagerProtocol: Sendable {
    /// Whether users had choosen Proton Pass as AutoFill Provider
    var isAutoFillEnabled: Bool { get async }

    func remove(credentials: [AutoFillCredential]) async throws
    func insert(credentials: [AutoFillCredential]) async throws
    func removeAllCredentials() async throws
}

public final class CredentialManager {
    public let store: ASCredentialIdentityStore
    public let logger: Logger

    public init(logManager: any LogManagerProtocol,
                store: ASCredentialIdentityStore = .shared) {
        self.store = store
        logger = .init(manager: logManager)
    }
}

extension CredentialManager: CredentialManagerProtocol {
    public var isAutoFillEnabled: Bool {
        get async {
            await store.state().isEnabled
        }
    }

    public func remove(credentials: [AutoFillCredential]) async throws {
        logger.trace("Trying to remove \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing \(credentials.count) credentials.")
            return
        }

        let domainCredentials = try credentials.map { try ASPasswordCredentialIdentity($0) }
        if state.supportsIncrementalUpdates {
            logger.trace("Non empty credential store. Removing \(credentials.count) credentials.")
            try await store.removeCredentialIdentities(domainCredentials)
        } else {
            logger.trace("Empty credential store. Nothing to remove.")
        }
    }

    public func insert(credentials: [AutoFillCredential]) async throws {
        logger.trace("Trying to insert \(credentials.count) credentials.")
        let state = await store.state()
        guard state.isEnabled else {
            logger.trace("AutoFill is not enabled. Skipped inserting \(credentials.count) credentials.")
            return
        }

        let domainCredentials = try credentials.map { try ASPasswordCredentialIdentity($0) }

        if state.supportsIncrementalUpdates {
            logger.trace("Non empty credential store. Inserting \(credentials.count) credentials.")
            try await store.saveCredentialIdentities(domainCredentials)
        } else {
            logger.trace("Empty credential store. Inserting \(credentials.count) credentials.")
            try await store.replaceCredentialIdentities(with: domainCredentials)
        }
        logger.trace("Inserted \(credentials.count) credentials.")
    }

    public func removeAllCredentials() async throws {
        logger.trace("Removing all credentials.")
        guard await isAutoFillEnabled else {
            logger.trace("AutoFill is not enabled. Skipped removing all credentials.")
            return
        }
        try await store.removeAllCredentialIdentities()
        logger.trace("Removed all credentials.")
    }
}
