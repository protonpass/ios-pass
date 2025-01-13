//
// SharedTooling+DependencyInjections.swift
// Proton Pass - Created on 07/06/2023.
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
import CoreData
import CryptoKit
import Entities
import Factory
import LocalAuthentication
import ProtonCoreDoh
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreLoginUI

/// Contain tools shared between main iOS app and extensions
final class SharedToolingContainer: SharedContainer, AutoRegistering {
    static let shared = SharedToolingContainer()
    let manager = ContainerManager()

    private init() {
        Self.setUpContext()
    }

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

// MARK: Shared Logging tools

extension SharedToolingContainer {
    var specificLogManager: ParameterFactory<PassModule, LogManager> {
        self { LogManager(module: $0) }
            .unique
    }

    var logManager: Factory<any LogManagerProtocol> {
        self { LogManager(module: .hostApp) }
            .onArg(PassModule.autoFillExtension) { LogManager(module: .autoFillExtension) }
            .onArg(PassModule.shareExtension) { LogManager(module: .shareExtension) }
    }

    var logFormatter: Factory<any LogFormatterProtocol> {
        self { LogFormatter(format: .txt) }
    }

    /// A `Logger` that has `shared` scope because while all logger instances share a unique `logManager`
    /// each of them should have a different `subsystem` &`category`, so the scope cannot be `unique` or
    /// `singleton`
    var logger: Factory<Logger> {
        self { Logger(manager: self.logManager()) }
            .shared
    }
}

// MARK: Data tools

extension SharedToolingContainer {
    var doh: Factory<any DoHInterface> {
        self { ProtonPassDoH() }
    }

    var module: Factory<PassModule> {
        self { .hostApp }
            .onArg(PassModule.autoFillExtension) { .autoFillExtension }
            .onArg(PassModule.shareExtension) { .shareExtension }
    }

    var appVersion: Factory<String> {
        self { "ios-pass@\(Bundle.main.fullAppVersionName)" }
            .onArg(PassModule.autoFillExtension) {
                "ios-pass-autofill@\(Bundle.main.fullAppVersionName)"
            }
            .onArg(PassModule.shareExtension) {
                "ios-pass-share@\(Bundle.main.fullAppVersionName)"
            }
    }

    var apiManager: Factory<APIManager> {
        self { APIManager(authManager: self.authManager(),
                          userManager: SharedServiceContainer.shared.userManager(),
                          themeProvider: self.preferencesManager(),
                          appVersion: self.appVersion(),
                          doh: self.doh(),
                          logManager: self.logManager()) }
    }

    var apiServiceLite: Factory<any ApiServiceLiteProtocol> {
        self { ApiServiceLite(appVersion: self.appVersion(),
                              doh: self.doh(),
                              authManager: self.authManager()) }
    }
}

// MARK: User centric tools

extension SharedToolingContainer {
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }

    var theme: Factory<Theme> {
        self { self.preferencesManager().sharedPreferences.unwrapped().theme }
            .unique
    }

    var currentDateProvider: Factory<any CurrentDateProviderProtocol> {
        self { CurrentDateProvider() }
    }

    var preferencesManager: Factory<any PreferencesManagerProtocol> {
        self {
            let cont = SharedRepositoryContainer.shared
            return PreferencesManager(userManager: SharedServiceContainer.shared.userManager(),
                                      appPreferencesDatasource: cont.appPreferencesDatasource(),
                                      sharedPreferencesDatasource: cont.sharedPreferencesDatasource(),
                                      userPreferencesDatasource: cont.userPreferencesDatasource(),
                                      logManager: self.logManager(),
                                      preferencesMigrator: self.preferences())
        }
    }
}

// MARK: Keychain tools

extension SharedToolingContainer {
    private var baseKeychain: Factory<PPKeychain> {
        self { PPKeychain() }
    }

    var keychain: Factory<any KeychainProtocol> {
        self { self.baseKeychain() }
    }

    var settingsProvider: Factory<any SettingsProvider> {
        self { self.baseKeychain() }
    }

    var autolocker: Factory<Autolocker> {
        self { Autolocker(lockTimeProvider: self.settingsProvider()) }
    }

    var mainKeyProvider: Factory<any MainKeyProvider> {
        self { Keymaker(autolocker: self.autolocker(),
                        keychain: self.baseKeychain()) }
    }
}

// MARK: Authentication

extension SharedToolingContainer {
    var authManager: Factory<any AuthManagerProtocol> {
        self {
            AuthManager(keychain: SharedToolingContainer.shared.keychain(),
                        symmetricKeyProvider: SharedDataContainer.shared.nonSendableSymmetricKeyProvider(),
                        module: self.module(),
                        logManager: self.logManager())
        }
    }

    /// Used when users enable biometric authentication. Always fallback to device passcode in this case.
    var localAuthenticationEnablingPolicy: Factory<LAPolicy> {
        self { .deviceOwnerAuthentication }
    }
}

extension SharedToolingContainer {
    var authDeviceManagerUI: Factory<AuthDeviceManagerUI> {
        self {
            let authDeviceManager = AuthDeviceManager(userManagerProvider: SharedServiceContainer.shared
                .userManager(),
                apiManagerProvider: self.apiManager())
            return AuthDeviceManagerUI(authDeviceManager: authDeviceManager)
        }
    }
}
