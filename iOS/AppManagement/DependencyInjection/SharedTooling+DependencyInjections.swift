//
// SharedTooling+DependencyInjection.swift
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

import Core
import Factory
import ProtonCore_Keymaker

/// Contain tools shared between main iOS app and extensions
final class SharedToolingContainer: SharedContainer {
    static let shared = SharedToolingContainer()
    let manager = ContainerManager()

    private init() {
        let key = "ProtonPass"
        switch Bundle.main.infoDictionary?["MODULE"] as? String {
        case "AUTOFILL_EXTENSION":
            FactoryContext.setArg(PassModule.autoFillExtension, forKey: key)
        case "KEYBOARD_EXTENSION":
            FactoryContext.setArg(PassModule.keyboardExtension, forKey: key)
        default:
            // Default to host app
            break
        }
    }

    func resetCache() {
        manager.reset(scope: .cached)
    }
}

// MARK: Shared Logging tools

extension SharedToolingContainer {
    var specificLogManager: ParameterFactory<PassModule, LogManager> {
        self { LogManager(module: $0) }
            .unique
    }

    var logManager: Factory<LogManager> {
        self { LogManager(module: .hostApp) }
            .onArg(PassModule.autoFillExtension) { LogManager(module: .autoFillExtension) }
            .onArg(PassModule.keyboardExtension) { LogManager(module: .keyboardExtension) }
    }

    var logFormatter: Factory<LogFormatterProtocol> {
        self { LogFormatter(format: .txt) }
    }
}

// MARK: Data tools

extension SharedToolingContainer {
    var appData: Factory<AppData> {
        self { AppData() }
    }

    var apiManager: Factory<APIManager> {
        self { APIManager(logManager: self.logManager(),
                          appVer: "ios-pass@\(Bundle.main.fullAppVersionName)",
                          appData: self.appData(),
                          preferences: self.preferences()) }
            .onArg(PassModule.autoFillExtension) {
                APIManager(logManager: self.logManager(),
                           appVer: "ios-pass-autofill-extension@\(Bundle.main.fullAppVersionName)",
                           appData: self.appData(),
                           preferences: self.preferences())
            }
    }
}

// MARK: User centric tools

extension SharedToolingContainer {
    var preferences: Factory<Preferences> {
        self { Preferences() }
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

extension SharedToolingContainer: AutoRegistering {
    func autoRegister() {
        manager.defaultScope = .singleton
    }
}
