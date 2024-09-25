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

public let kLegacySymmetricKey = "symmetricKey"
public let kSymmetricKey = "SymmetricKey"

// sourcery: AutoMockable
public protocol SymmetricKeyProvider: Sendable {
    /// Return an application-wide symmetric key
    /// Generate a random one if not any, encrypt with the main key and save to keychain
    func getSymmetricKey() async throws -> SymmetricKey
}

public actor SymmetricKeyProviderImpl: SymmetricKeyProvider {
    private let keychain: any KeychainProtocol
    private let mainKeyProvider: any MainKeyProvider

    private var cachedKey: SymmetricKey?

    public init(keychain: any KeychainProtocol,
                mainKeyProvider: any MainKeyProvider) {
        self.keychain = keychain
        self.mainKeyProvider = mainKeyProvider
    }
}

public extension SymmetricKeyProviderImpl {
    func getSymmetricKey() async throws -> SymmetricKey {
        if let cachedKey {
            return cachedKey
        }

        let key = try SymmetricKeyGetter.getOrRandomSymmetricKey(keychain: keychain,
                                                                 mainKeyProvider: mainKeyProvider)
        cachedKey = key
        return key
    }

    func clearCache() {
        cachedKey = nil
    }
}

// sourcery: AutoMockable
/// Non `Sendable` variant with no cache mechanism for usages in non concurrency contexts
/// where it's impossible to introduce async functions like `AuthManager`
public protocol NonSendableSymmetricKeyProvider {
    func getSymmetricKey() throws -> SymmetricKey
}

public final class NonSendableSymmetricKeyProviderImpl: NonSendableSymmetricKeyProvider {
    private let keychain: any KeychainProtocol
    private let mainKeyProvider: any MainKeyProvider

    public init(keychain: any KeychainProtocol,
                mainKeyProvider: any MainKeyProvider) {
        self.keychain = keychain
        self.mainKeyProvider = mainKeyProvider
    }
}

public extension NonSendableSymmetricKeyProviderImpl {
    func getSymmetricKey() throws -> SymmetricKey {
        try SymmetricKeyGetter.getOrRandomSymmetricKey(keychain: keychain,
                                                       mainKeyProvider: mainKeyProvider)
    }
}

private enum SymmetricKeyGetter {
    static func getOrRandomSymmetricKey(keychain: any KeychainProtocol,
                                        mainKeyProvider: any MainKeyProvider) throws -> SymmetricKey {
        guard let mainKey = mainKeyProvider.mainKey else {
            throw PassError.mainKeyNotFound
        }

        // Lock and save key data to keychain after migration or random generation
        let lockAndSaveToKeychain: (Data) throws -> Void = { keyData in
            let lockedData = try Locked<Data>(clearValue: keyData, with: mainKey)
            try keychain.setOrError(lockedData.encryptedValue, forKey: kSymmetricKey)
        }

        // If legacy key is found => migrate to new key & remove legacy key
        if let legacyKey = try Self.getLegacyKey(keychain: keychain,
                                                 mainKeyProvider: mainKeyProvider) {
            try lockAndSaveToKeychain(legacyKey)
            try keychain.removeOrError(forKey: kLegacySymmetricKey)
        }

        // At this point either migration is done or no key is generated (first installation)
        // so we proceed as normal (get if exist and random if not)
        if let lockedSymmetricKeyData = try keychain.dataOrError(forKey: kSymmetricKey) {
            let lockedData = Locked<Data>(encryptedValue: lockedSymmetricKeyData)
            let unlockedData = try lockedData.unlock(with: mainKey)
            return .init(data: unlockedData)
        } else {
            let randomData = try Data.random()
            try lockAndSaveToKeychain(randomData)
            return .init(data: randomData)
        }
    }

    /// Due to legacy reason, we used to encode/decode base 64 data before storing/getting from keychain,
    /// So we need these special logics to get and migrate
    static func getLegacyKey(keychain: any KeychainProtocol,
                             mainKeyProvider: any MainKeyProvider) throws -> Data? {
        // The JSON representation of the encoded base 64 string
        guard let cypherEncodedBase64 = try keychain.dataOrError(forKey: kLegacySymmetricKey) else {
            return nil
        }

        guard let mainKey = mainKeyProvider.mainKey else {
            throw PassError.mainKeyNotFound
        }

        let lockedEncodedBase64 = Locked<Data>(encryptedValue: cypherEncodedBase64)
        let unlockedEncodedData = try lockedEncodedBase64.unlock(with: mainKey)
        let base64 = try JSONDecoder().decode(String.self, from: unlockedEncodedData)
        return try base64.base64Decode()
    }
}
