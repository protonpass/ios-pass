//
// SharedDataContainer+DependencyInjections.swift
// Proton Pass - Created on 25/07/2023.
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
import Foundation
import ProtonCoreLogin

final class SharedDataContainer: SharedContainer, AutoRegistering {
    static let shared = SharedDataContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .singleton
    }
}

extension SharedDataContainer {
    var loginMethod: Factory<LoginMethodFlow> {
        self { LoginMethodFlow() }
    }

    private var appData: Factory<FullDataProvider> {
        self { AppData() }
    }

    var fullDataProvider: Factory<FullDataProvider> {
        self { self.appData() }
    }

    var userDataProvider: Factory<UserDataProvider> {
        self { self.appData() }
    }

    var credentialProvider: Factory<CredentialProvider> {
        self { self.appData() }
    }

    var symmetricKeyProvider: Factory<SymmetricKeyProvider> {
        self { self.appData() }
    }
}
