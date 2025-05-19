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
import FactoryKit
import ProtonCoreCryptoGoImplementation

final class CredentialProviderViewController: ASCredentialProviderViewController {
    private lazy var coordinator: CredentialProviderCoordinator = .init(rootViewController: self,
                                                                        context: extensionContext)
    private let resetFactory = resolve(\AutoFillUseCaseContainer.resetFactory)

    override func viewDidLoad() {
        super.viewDidLoad()
        injectDefaultCryptoImplementation()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .recordLastActiveTimestamp, object: nil)
        resetFactory()
    }

    /// Can be removed onced dropped iOS 16
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        coordinator.setUpAndStart(mode: .showAllLogins(serviceIdentifiers, nil))
    }

    /// Can be removed onced dropped iOS 16
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.setUpAndStart(mode: .checkAndAutoFill(.password(credentialIdentity)))
    }

    /// Can be removed onced dropped iOS 16
    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.setUpAndStart(mode: .authenticateAndAutofill(.password(credentialIdentity)))
    }

    /// Passkey-agnostic, must always implement this function
    override func prepareInterfaceForExtensionConfiguration() {
        coordinator.setUpAndStart(mode: .configuration)
    }

    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        coordinator.setUpAndStart(mode: .showOneTimeCodes(serviceIdentifiers))
    }

    override func prepareInterfaceForUserChoosingTextToInsert() {
        coordinator.setUpAndStart(mode: .arbitraryTextInsertion)
    }
}

/* Other callbacks are superseded by these new callbacks on iOS 17 in the below extension */

// MARK: Passkey support

@available(iOSApplicationExtension 17.0, *)
extension CredentialProviderViewController {
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier],
                                        requestParameters: ASPasskeyCredentialRequestParameters) {
        coordinator.setUpAndStart(mode: .showAllLogins(serviceIdentifiers, requestParameters))
    }

    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        guard let autoFillRequest = credentialRequest.autoFillRequest else { return }
        coordinator.setUpAndStart(mode: .checkAndAutoFill(autoFillRequest))
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        guard let autoFillRequest = credentialRequest.autoFillRequest else { return }
        coordinator.setUpAndStart(mode: .authenticateAndAutofill(autoFillRequest))
    }

    override func prepareInterface(forPasskeyRegistration registrationRequest: any ASCredentialRequest) {
        guard let passkeyCredentialRequest = registrationRequest.passkeyCredentialRequest else {
            return
        }
        coordinator.setUpAndStart(mode: .passkeyRegistration(passkeyCredentialRequest))
    }
}
