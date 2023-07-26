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
import Factory
import Foundation
import ProtonCore_Login

final class SharedDataContainer: SharedContainer, AutoRegistering {
    static let shared = SharedDataContainer()
    let manager = ContainerManager()

    func autoRegister() {
        manager.defaultScope = .cached
    }

    func resolve(container: NSPersistentContainer,
                 symmetricKey: SymmetricKey,
                 userData: UserData,
                 manualLogIn: Bool) {
        self.container.register { container }
        self.symmetricKey.register { symmetricKey }
        self.userData.register { userData }
        self.manualLogIn.register { manualLogIn }
    }
}

extension SharedDataContainer {
    var container: Factory<NSPersistentContainer> {
        self { fatalError("container not registered") }
    }

    var symmetricKey: Factory<SymmetricKey> {
        self { fatalError("symmetricKey not registered") }
    }

    var userData: Factory<UserData> {
        self { fatalError("userData not registered") }
    }

    var manualLogIn: Factory<Bool> {
        self { fatalError("manualLogIn not registered") }
    }
}
