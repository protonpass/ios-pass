//
// DatasourceDI.swift
// Proton Pass - Created on 08/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Combine
import Core
import CryptoKit
import Entities
import FactoryKit
import Foundation

public final class DataContainer: SharedContainer, AutoRegistering {
    public static let shared = DataContainer()
    public let manager = ContainerManager()

    private init() {
        Self.setUpContext()
    }

    public func autoRegister() {
        manager.defaultScope = .singleton
    }
}

private extension DataContainer {
    var keychain: any KeychainProtocol {
        ToolingContainer.shared.keychain()
    }

    var mainKeyProvider: any MainKeyProvider {
        ToolingContainer.shared.mainKeyProvider()
    }
}

public extension DataContainer {
    var loginMethod: Factory<LoginMethodFlow> {
        self { LoginMethodFlow() }
    }

    var credentialProvider: Factory<any AuthManagerProtocol> {
        self { ToolingContainer.shared.authManager() }
    }

    var symmetricKeyProvider: Factory<any SymmetricKeyProvider> {
        self { SymmetricKeyProviderImpl(keychain: self.keychain,
                                        mainKeyProvider: self.mainKeyProvider) }
    }

    var nonSendableSymmetricKeyProvider: Factory<any NonAsyncSymmetricKeyProvider> {
        self { NonSendableSymmetricKeyProviderImpl(keychain: self.keychain,
                                                   mainKeyProvider: self.mainKeyProvider) }
    }
}

// MARK: - Data streams

public extension DataContainer {
    var currentSelectedItems: Factory<CurrentValueSubject<[ItemUiModel], Never>> {
        self { .init([]) }
    }

    var monitorStateStream: Factory<MonitorStateStream> {
        self { MonitorStateStream(.default) }
    }

    var itemTypeSelection: Factory<PassthroughSubject<ItemContentType, Never>> {
        self { .init() }
    }
}
