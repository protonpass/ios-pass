//
// ASCredentialRequest+Extensions.swift
// Proton Pass - Created on 26/02/2024.
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

import AuthenticationServices
import Entities

@available(iOS 17.0, *)
extension ASCredentialRequest {
    var passwordCredentialIdentity: ASPasswordCredentialIdentity? {
        guard let request = self as? ASPasswordCredentialRequest,
              let credentialIdentity = request.credentialIdentity as? ASPasswordCredentialIdentity else {
            assertionFailure("Failed to extract request's information")
            return nil
        }
        return credentialIdentity
    }

    var passkeyCredentialRequest: PasskeyCredentialRequest? {
        guard let request = self as? ASPasskeyCredentialRequest,
              let credentialIdentity = request.credentialIdentity as? ASPasskeyCredentialIdentity else {
            assertionFailure("Failed to extract request's information")
            return nil
        }
        return PasskeyCredentialRequest(userName: credentialIdentity.userName,
                                        relyingPartyIdentifier: credentialIdentity
                                            .relyingPartyIdentifier,
                                        serviceIdentifier: credentialIdentity.serviceIdentifier,
                                        recordIdentifier: credentialIdentity.recordIdentifier,
                                        clientDataHash: request.clientDataHash,
                                        userHandle: credentialIdentity.userHandle,
                                        supportedAlgorithms: request.supportedAlgorithms)
    }

    @available(iOSApplicationExtension 18.0, *)
    var oneTimeCodeCredentialIdentity: ASOneTimeCodeCredentialIdentity? {
        guard let request = self as? ASOneTimeCodeCredentialRequest,
              let credentialIdentity = request.credentialIdentity as? ASOneTimeCodeCredentialIdentity else {
            assertionFailure("Failed to extract request's information")
            return nil
        }
        return credentialIdentity
    }

    var autoFillRequest: AutoFillRequest? {
        switch type {
        case .password:
            if let passwordCredentialIdentity {
                return .password(passwordCredentialIdentity)
            }

        case .passkeyAssertion:
            if let passkeyCredentialRequest {
                return .passkey(passkeyCredentialRequest)
            }

        case .oneTimeCode:
            if #available(iOS 18, *), let identity = oneTimeCodeCredentialIdentity {
                return .oneTimeCode(.init(serviceIdentifier: identity.serviceIdentifier,
                                          recordIdentifier: identity.recordIdentifier))
            }

        case .passkeyRegistration:
            // Not yet supported
            break

        @unknown default:
            assertionFailure("Unknown credential request type")
            return nil
        }
        return nil
    }
}
