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
import ProtonCoreServices

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

    var logManager: Factory<LogManagerProtocol> {
        self { LogManager(module: .hostApp) }
            .onArg(PassModule.autoFillExtension) { LogManager(module: .autoFillExtension) }
            .onArg(PassModule.keyboardExtension) { LogManager(module: .keyboardExtension) }
    }

    var logFormatter: Factory<LogFormatterProtocol> {
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
    var doh: Factory<DoHInterface> {
        self { ProtonPassDoH() }
    }

    var module: Factory<PassModule> {
        self { .hostApp }
            .onArg(PassModule.autoFillExtension) { .autoFillExtension }
            .onArg(PassModule.keyboardExtension) { .keyboardExtension }
    }

    var appVersion: Factory<String> {
        self { "ios-pass@\(Bundle.main.fullAppVersionName)" }
            .onArg(PassModule.autoFillExtension) {
                "ios-pass-autofill-extension@\(Bundle.main.fullAppVersionName)"
            }
    }

    var apiManager: Factory<APIManager> {
        self { APIManager() }
    }
}

// MARK: User centric tools

extension SharedToolingContainer {
    var preferences: Factory<Preferences> {
        self { Preferences() }
    }

    var theme: Factory<Theme> {
        self { self.preferences().theme }
            .unique
    }

    var currentDateProvider: Factory<CurrentDateProviderProtocol> {
        self { CurrentDateProvider() }
    }
}

// MARK: Keychain tools

extension SharedToolingContainer {
    private var baseKeychain: Factory<PPKeychain> {
        self { PPKeychain() }
    }

    var keychain: Factory<KeychainProtocol> {
        self { self.baseKeychain() }
    }

    var settingsProvider: Factory<SettingsProvider> {
        self { self.baseKeychain() }
    }

    var autolocker: Factory<Autolocker> {
        self { Autolocker(lockTimeProvider: self.settingsProvider()) }
    }

    var mainKeyProvider: Factory<MainKeyProvider> {
        self { Keymaker(autolocker: self.autolocker(),
                        keychain: self.baseKeychain()) }
    }
}

// MARK: Authentication

extension SharedToolingContainer {
    var authManager: Factory<AuthManagerProtocol> {
        self { AuthManager(credentialProvider: SharedDataContainer.shared.credentialProvider()) }
    }

    /// Used when users enable biometric authentication. Always fallback to device passcode in this case.
    var localAuthenticationEnablingPolicy: Factory<LAPolicy> {
        self { .deviceOwnerAuthentication }
    }
}
