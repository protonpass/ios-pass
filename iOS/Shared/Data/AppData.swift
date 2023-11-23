//
// AppData.swift
// Proton Pass - Created on 01/04/2023.
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

import Client
import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking

public extension LockedKeychainStorage {
    /// Conveniently initialize with injected `keychain`, `mainKeyProvider` & `logManager`
    init(key: any RawRepresentable<String>, defaultValue: Value) {
        self.init(key: key.rawValue,
                  defaultValue: defaultValue,
                  keychain: SharedToolingContainer.shared.keychain(),
                  mainKeyProvider: SharedToolingContainer.shared.mainKeyProvider(),
                  logManager: SharedToolingContainer.shared.logManager())
    }
}

enum AppDataKey: String {
    case userData
    case symmetricKey
    case hostAppCredential
    case autofillExtensionCredential
    case unauthCredential
}

extension UserData: @unchecked Sendable {}

final class AppData: AppDataProtocol {
    @LockedKeychainStorage(key: AppDataKey.userData, defaultValue: nil)
    private var userData: UserData?

    @LockedKeychainStorage(key: AppDataKey.symmetricKey, defaultValue: nil)
    private var symmetricKey: String?

    @LockedKeychainStorage(key: AppDataKey.hostAppCredential, defaultValue: nil)
    private var hostAppCredential: AuthCredential?

    @LockedKeychainStorage(key: AppDataKey.autofillExtensionCredential, defaultValue: nil)
    private var autofillExtensionCredential: AuthCredential?

    @LockedKeychainStorage(key: AppDataKey.unauthCredential, defaultValue: nil)
    private var unauthCredential: AuthCredential?

    private let module: PassModule

    init(module: PassModule) {
        self.module = module
    }

    func getSymmetricKey() throws -> SymmetricKey {
        if let symmetricKey {
            guard let symmetricKeyData = try symmetricKey.base64Decode() else {
                throw PassError.failedToGetOrCreateSymmetricKey
            }
            return .init(data: symmetricKeyData)
        } else {
            let randomData = try Data.random()
            symmetricKey = randomData.encodeBase64()
            return .init(data: randomData)
        }
    }

    func removeSymmetricKey() {
        symmetricKey = nil
    }

    func setUserData(_ userData: UserData?) {
        self.userData = userData
        // Should be removed after session forking
        useCredentialInUserDataForBothAppAndExtension()
    }

    func getUserData() -> UserData? {
        userData
    }

    func getCredential() -> AuthCredential? {
        if userData != nil {
            switch module {
            case .hostApp:
                assert(hostAppCredential != nil, "Expect not nil hostAppCredential")
                return hostAppCredential
            case .autoFillExtension:
                assert(autofillExtensionCredential != nil, "Expect not nil autofillExtensionCredential")
                return autofillExtensionCredential
            case .keyboardExtension:
                fatalError("Not applicable")
            }
        } else {
            return unauthCredential
        }
    }

    func setCredential(_ credential: AuthCredential?) {
        if userData != nil {
            switch module {
            case .hostApp:
                assert(hostAppCredential != nil, "Expect not nil hostAppCredential")
                hostAppCredential = credential
                // Should be removed after session forking
                autofillExtensionCredential = credential

            case .autoFillExtension:
                assert(autofillExtensionCredential != nil, "Expect not nil autofillExtensionCredential")
                autofillExtensionCredential = credential
                // Should be removed after session forking
                hostAppCredential = credential

            case .keyboardExtension:
                fatalError("Not applicable")
            }
        } else {
            unauthCredential = credential
        }
    }

    func resetData() {
        userData = nil
        symmetricKey = nil
        hostAppCredential = nil
        autofillExtensionCredential = nil
        unauthCredential = nil
    }

    // Should be removed after session forking
    func migrateToSeparatedCredentials() {
        useCredentialInUserDataForBothAppAndExtension()
    }
}

private extension AppData {
    func useCredentialInUserDataForBothAppAndExtension() {
        if let userData {
            hostAppCredential = userData.credential
            autofillExtensionCredential = userData.credential
        }
    }
}
