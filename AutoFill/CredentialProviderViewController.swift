//
// CredentialProviderViewController.swift
// Proton Pass - Created on 26/09/2022.
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

import AuthenticationServices
import Entities
import Factory
import ProtonCoreCryptoGoImplementation

final class CredentialProviderViewController: ASCredentialProviderViewController {
    private lazy var coordinator: CredentialProviderCoordinator = .init(rootViewController: self)
    private let resetFactory = resolve(\AutoFillUseCaseContainer.resetFactory)

    override func viewDidLoad() {
        super.viewDidLoad()

        injectDefaultCryptoImplementation()
        AutoFillDataContainer.shared.register(context: extensionContext)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        resetFactory()
    }

    /// Can be removed onced dropped iOS 16
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        coordinator.start(mode: .showAllLogins(serviceIdentifiers, nil))
    }

    /// Can be removed onced dropped iOS 16
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.start(mode: .checkAndAutoFill(.password(credentialIdentity)))
    }

    /// Can be removed onced dropped iOS 16
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.start(mode: .authenticateAndAutofill(.password(credentialIdentity)))
    }

    /// Passkey-agnostic, must always implement this function
    override func prepareInterfaceForExtensionConfiguration() {
        coordinator.start(mode: .configuration)
    }
}

/* Other callbacks are superseded by these new callbacks on iOS 17 in the below extension */

// MARK: Passkey support

@available(iOSApplicationExtension 17.0, *)
extension CredentialProviderViewController {
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier],
                                        requestParameters: ASPasskeyCredentialRequestParameters) {
        coordinator.start(mode: .showAllLogins(serviceIdentifiers, requestParameters))
    }

    override func provideCredentialWithoutUserInteraction(for credentialRequest: ASCredentialRequest) {
        autoFill(with: credentialRequest, withoutUserInteraction: true)
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: ASCredentialRequest) {
        autoFill(with: credentialRequest, withoutUserInteraction: false)
    }

    override func prepareInterface(forPasskeyRegistration registrationRequest: ASCredentialRequest) {
        coordinator.start(mode: .passkeyRegistration)
    }

    func autoFill(with credentialRequest: ASCredentialRequest, withoutUserInteraction: Bool) {
        switch credentialRequest.type {
        case .password:
            guard let request = credentialRequest as? ASPasswordCredentialRequest,
                  let credentialIdentity = request.credentialIdentity as? ASPasswordCredentialIdentity else {
                assertionFailure("Failed to extract request's information")
                return
            }
            if withoutUserInteraction {
                coordinator.start(mode: .checkAndAutoFill(.password(credentialIdentity)))
            } else {
                coordinator.start(mode: .authenticateAndAutofill(.password(credentialIdentity)))
            }

        case .passkeyAssertion:
            guard let request = credentialRequest as? ASPasskeyCredentialRequest,
                  let credentialIdentity = request.credentialIdentity as? ASPasskeyCredentialIdentity else {
                assertionFailure("Failed to extract request's information")
                return
            }

            let passkeyRequest = PasskeyCredentialRequest(userName: credentialIdentity.userName,
                                                          relyingPartyIdentifier: credentialIdentity
                                                              .relyingPartyIdentifier,
                                                          serviceIdentifier: credentialIdentity.serviceIdentifier,
                                                          recordIdentifier: credentialIdentity.recordIdentifier,
                                                          clientDataHash: request.clientDataHash)
            if withoutUserInteraction {
                coordinator.start(mode: .checkAndAutoFill(.passkey(passkeyRequest)))
            } else {
                coordinator.start(mode: .authenticateAndAutofill(.passkey(passkeyRequest)))
            }

        @unknown default:
            assertionFailure("Unknown credential request type")
        }
    }
}
