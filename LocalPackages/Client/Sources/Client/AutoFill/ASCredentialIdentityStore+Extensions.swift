//
// ASCredentialIdentityStore+Extensions.swift
// Proton Pass - Created on 28/02/2024.
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
//

import AuthenticationServices
import Entities

extension ASCredentialIdentityStore {
    enum Action {
        case save, replace, remove
    }

    func performAction(_ action: Action, on credentials: [CredentialIdentity]) async throws {
        if #available(iOS 17, *) {
            try await performActionWithPasskeys(action, on: credentials)
        } else {
            try await performActionWithoutPasskeys(action, on: credentials)
        }
    }
}

private extension ASCredentialIdentityStore {
    @available(iOS 17.0, *)
    func performActionWithPasskeys(_ action: Action, on credentials: [CredentialIdentity]) async throws {
        let domainCredentials: [any ASCredentialIdentity] = try credentials.compactMap { creds in
            switch creds {
            case let .password(identity):
                try identity.toASPasswordCredentialIdentity()

            case let .oneTimeCode(identity):
                if #available(iOS 18.0, *) {
                    try identity.toASOneTimeCodeCredentialIdentity()
                } else {
                    nil
                }

            case let .passkey(identity):
                try identity.toASPasskeyCredentialIdentity()
            }
        }
        switch action {
        case .save:
            try await saveCredentialIdentities(domainCredentials)
        case .replace:
            try await replaceCredentialIdentities(domainCredentials)
        case .remove:
            try await removeCredentialIdentities(domainCredentials)
        }
    }

    func performActionWithoutPasskeys(_ action: Action,
                                      on credentials: [CredentialIdentity]) async throws {
        let domainCredentials: [ASPasswordCredentialIdentity] = try credentials.compactMap {
            switch $0 {
            case let .password(identity):
                try identity.toASPasswordCredentialIdentity()
            case .oneTimeCode, .passkey:
                nil
            }
        }
        switch action {
        case .save:
            try await saveCredentialIdentities(domainCredentials)
        case .replace:
            try await replaceCredentialIdentities(with: domainCredentials)
        case .remove:
            try await removeCredentialIdentities(domainCredentials)
        }
    }
}

private extension PasswordCredentialIdentity {
    func toASPasswordCredentialIdentity() throws -> ASPasswordCredentialIdentity {
        let identifier = ASCredentialServiceIdentifier(identifier: url, type: .URL)
        let identity = try ASPasswordCredentialIdentity(serviceIdentifier: identifier,
                                                        user: username,
                                                        recordIdentifier: ids.serializeBase64())
        identity.rank = Int(lastUseTime)
        return identity
    }
}

private extension OneTimeCodeIdentity {
    @available(iOS 18.0, *)
    func toASOneTimeCodeCredentialIdentity() throws -> ASOneTimeCodeCredentialIdentity {
        let identifier = ASCredentialServiceIdentifier(identifier: url, type: .URL)
        return try .init(serviceIdentifier: identifier,
                         label: username,
                         recordIdentifier: ids.serializeBase64())
    }
}

@available(iOS 17.0, *)
private extension PasskeyCredentialIdentity {
    func toASPasskeyCredentialIdentity() throws -> ASPasskeyCredentialIdentity {
        try ASPasskeyCredentialIdentity(relyingPartyIdentifier: relyingPartyIdentifier,
                                        userName: userName,
                                        credentialID: credentialId,
                                        userHandle: userHandle,
                                        recordIdentifier: ids.serializeBase64())
    }
}
