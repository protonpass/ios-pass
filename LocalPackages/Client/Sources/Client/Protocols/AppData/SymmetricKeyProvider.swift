//
// SymmetricKeyProvider.swift
// Proton Pass - Created on 03/11/2023.
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
//

// periphery:ignore:all
import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreKeymaker

private let kSymmetricKey = "SymmetricKey"

// sourcery: AutoMockable
public protocol SymmetricKeyProvider: Sendable {
    /// Return an application-wide symmetric key
    /// Generate a random one if not any, encrypt with the main key and save to keychain
    func getSymmetricKey() throws -> SymmetricKey
}

public final class SymmetricKeyProviderImpl: SymmetricKeyProvider {
    private let keychain: any KeychainProtocol
    private let mainKeyProvider: any MainKeyProvider

    init(keychain: any KeychainProtocol,
         mainKeyProvider: any MainKeyProvider) {
        self.keychain = keychain
        self.mainKeyProvider = mainKeyProvider
    }
}

public extension SymmetricKeyProviderImpl {
    func getSymmetricKey() throws -> SymmetricKey {
        guard let mainKey = mainKeyProvider.mainKey else {
            throw PassError.mainKeyNotFound
        }

        if let lockedData = try keychain.dataOrError(forKey: kSymmetricKey) {
            let lockedData = Locked<Data>(encryptedValue: lockedData)
            let unlockedData = try lockedData.unlock(with: mainKey)
            return .init(data: unlockedData)
        } else {
            let randomData = try Data.random()
            let lockedData = try Locked<Data>(clearValue: randomData, with: mainKey).encryptedValue
            try keychain.setOrError(lockedData, forKey: kSymmetricKey)
            return .init(data: randomData)
        }
    }
}
