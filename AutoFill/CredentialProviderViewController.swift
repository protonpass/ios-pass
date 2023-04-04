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
import Client
import Core
import ProtonCore_Challenge
import ProtonCore_FeatureSwitch
import ProtonCore_Keymaker
import ProtonCore_Services

final class CredentialProviderViewController: ASCredentialProviderViewController {
    private lazy var coordinator = makeCoordinator()

    private func makeCoordinator() -> CredentialProviderCoordinator {
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        let logManager = LogManager(module: .autoFillExtension)
        let appVersion = "ios-pass-autofill-extension@\(Bundle.main.fullAppVersionName())"
        let appData = AppData(keychain: keychain, mainKeyProvider: keymaker, logManager: logManager)
        let apiManager = APIManager(logManager: logManager, appVer: appVersion, appData: appData)
        return .init(apiManager: apiManager,
                     container: .Builder.build(name: kProtonPassContainerName, inMemory: false),
                     context: extensionContext,
                     preferences: .init(),
                     logManager: logManager,
                     credentialManager: CredentialManager(logManager: logManager),
                     rootViewController: self)
    }

    /*
     Prepare your UI to list available credentials for the user to choose from. The items in
     'serviceIdentifiers' describe the service the user is logging in to, so your extension can
     prioritize the most relevant credentials in the list.
     */
    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        coordinator.start(with: serviceIdentifiers)
    }

     /*Implement this method if your extension supports showing credentials in the QuickType bar.
     When the user selects a credential from your app, this method will be called with the
     ASPasswordCredentialIdentity your app has previously saved to the ASCredentialIdentityStore.
     Provide the password by completing the extension request with the associated ASPasswordCredential.
     If using the credential would require showing custom UI for authenticating the user, cancel
     the request with error code ASExtensionError.userInteractionRequired.*/

    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.provideCredentialWithoutUserInteraction(for: credentialIdentity)
    }

    /*Implement this method if provideCredentialWithoutUserInteraction(for:) can fail with
     ASExtensionError.userInteractionRequired. In this case, the system may present your extension's
     UI and call this method. Show appropriate UI for authenticating the user then provide the password
     by completing the extension request with the associated ASPasswordCredential.*/

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        coordinator.provideCredentialWithBiometricAuthentication(for: credentialIdentity)
    }
}
