//
// VerifyPasswordTests.swift
// Proton Pass - Created on 12/10/2026.
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
import ClientMocks
import Combine
import Core
import Entities
import Foundation
import ProtonCoreCryptoGoImplementation
@preconcurrency import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreServices
import Testing
import UseCases
import UseCasesMocks

@Suite(.tags(.useCase))
struct VerifyPasswordTests {
    /// `static` so the global crypto implementation is installed exactly once.
    private static let cryptoIsInstalled: Bool = {
        injectDefaultCryptoImplementation()
        return true
    }()

    let userManager = UserManagerProtocolMock()
    let sut: VerifyPassword

    init() throws {
        _ = Self.cryptoIsInstalled
        userManager.stubbedGetActiveUserDataResult = try .sso(backupPassword: "backup password")
        sut = .init(userManager: userManager, apiManager: UnreachableAPIManager())
    }

    @Test func `SSO accounts are verified locally against their backup password`() async throws {
        #expect(try await sut("backup password"))
        #expect(try await sut("wrong password") == false)
    }
}

private extension UserData {
    static func sso(backupPassword: String) throws -> UserData {
        let keyId = String.random()
        let saltBytes = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let salt = KeySalt(ID: keyId, keySalt: saltBytes.base64EncodedString())
        let passphrases = try BuildAndValidatePassphrases().buildPassphrases(salts: [salt],
                                                                             mailboxPassword: backupPassword)
        let privateKey = try throwing { error in
            CryptoGo.HelperGenerateKey("test", "test", Data((passphrases[keyId] ?? "").utf8), "x25519", 0, &error)
        }
        let random = UserData.random()
        let user = User(ID: random.user.ID,
                        name: nil,
                        usedSpace: 0,
                        usedBaseSpace: nil,
                        usedDriveSpace: nil,
                        currency: "",
                        credit: 0,
                        maxSpace: 0,
                        maxBaseSpace: nil,
                        maxDriveSpace: nil,
                        maxUpload: 0,
                        role: 0,
                        private: 0,
                        subscribed: [],
                        services: 0,
                        delinquent: 0,
                        orgPrivateKey: nil,
                        email: nil,
                        displayName: nil,
                        keys: [.init(keyID: keyId, privateKey: privateKey, primary: 1)],
                        flags: .init(hasBYOEAddress: false, hasTemporaryPassword: false, sso: true))
        return UserData(credential: random.credential,
                        user: user,
                        salts: [salt],
                        passphrases: passphrases,
                        addresses: [],
                        scopes: [])
    }
}

/// SSO verification never goes through SRP, so reaching the API is a failure
private final class UnreachableAPIManager: APIManagerProtocol {
    var apiServiceWereUpdated: PassthroughSubject<any APIService, Never> {
        .init()
    }

    func getApiService(userId: String) throws -> any APIService {
        throw PassError.userManager(.activeUserDataNotFound)
    }

    // swiftlint:disable:next unavailable_function
    func getUnauthApiService() -> any APIService {
        fatalError("Not used by VerifyPassword")
    }

    func reset() {}
    func removeApiService(for userId: String) {}
}
