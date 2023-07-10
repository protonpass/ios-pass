//
// Tooling+DependencyInjections.swift
// Proton Pass - Created on 30/06/2023.
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

/// Contains tools specific to the iOS main app
final class ToolingContainer: SharedContainer {
    typealias FullKeychainService = SettingsProvider & Keychain

    static let shared = ToolingContainer()
    let manager = ContainerManager()
}

// MARK: Logging tools

extension ToolingContainer {
    var logManager: Factory<LogManager> {
        self { LogManager(module: .hostApp) }
    }

    var logger: Factory<Logger> {
        self { Logger(manager: self.logManager()) }
    }
}

// MARK: Data tools

extension ToolingContainer {
    var appData: Factory<AppData> {
        self { AppData(keychain: SharedToolingContainer.shared.keychain(),
                       mainKeyProvider: SharedToolingContainer.shared.keymaker(),
                       logManager: self.logManager()) }
    }

    var apiManager: Factory<APIManager> {
        self { APIManager(logManager: self.logManager(),
                          appVer: "ios-pass@\(Bundle.main.fullAppVersionName)",
                          appData: self.appData(),
                          preferences: SharedToolingContainer.shared.preferences()) }
    }
}

extension ToolingContainer: AutoRegistering {
    func autoRegister() {
        manager.defaultScope = .singleton
    }
}
