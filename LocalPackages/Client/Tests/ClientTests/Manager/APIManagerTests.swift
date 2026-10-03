//
// APIManagerTests.swift
// Proton Pass - Created on 10/07/2024.
// Copyright (c) 2024 Proton Technologies AG
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

@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import Foundation
import ProtonCoreAuthentication
import ProtonCoreCryptoGoImplementation
import ProtonCoreDoh
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreTestingToolkitUnitTestsCore
import Testing

public final class ProtonPassDoHMock: DoH, ServerConfig {
    public let environment: ProtonPassEnvironment
    public let signupDomain: String
    public let captchaHost: String
    public let humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    // periphery:ignore
    public let apiHost: String
    public let defaultPath: String
    public let proxyToken: String?

    public init(bundle: Bundle = .main, userDefaults: UserDefaults = .standard) {
        let environment: ProtonPassEnvironment = .black
        self.environment = environment
        signupDomain = "proton.me"
        captchaHost = "https://pass-api.proton.me"
        humanVerificationV3Host = "https://verify.proton.me"
        accountHost = "https://account.proton.me"
        defaultHost = "https://pass-api.proton.me"
        apiHost = "pass-api.proton.me"
        defaultPath = "/api"
        proxyToken = nil
    }
}

/// `.serialized`: `APIManager.init` writes process-wide ProtonCore statics (`TrustKitWrapper.current`,
/// `PMAPIService.trustKit`, `ObservabilityEnv.current`) without synchronisation, so two instances
/// must not be created concurrently. This is the only suite that creates one.
@Suite(.tags(.manager), .serialized)
struct APIManagerTests {
    /// `static` so the global crypto implementation is installed exactly once.
    private static let cryptoIsInstalled: Bool = {
        injectDefaultCryptoImplementation()
        return true
    }()

    private let userManager = UserManagerProtocolMock()
    private let themeProvider = ThemeProviderMock()
    private let authManager: any AuthManagerProtocol

    private let userData = UserData(
        credential: .init(sessionID: "test_session_id",
                          accessToken: "test_access_token",
                          refreshToken: "test_refresh_token",
                          userName: "test_user_name",
                          userID: "test_user_id",
                          privateKey: nil,
                          passwordKeySalt: nil),
        user: .init(ID: "test_user_id",
                    name: nil,
                    usedSpace: .zero,
                    usedBaseSpace: .zero,
                    usedDriveSpace: .zero,
                    currency: .empty,
                    credit: .zero,
                    maxSpace: .zero,
                    maxBaseSpace: .zero,
                    maxDriveSpace: .zero,
                    maxUpload: .zero,
                    role: .zero,
                    private: .zero,
                    subscribed: [],
                    services: .zero,
                    delinquent: .zero,
                    orgPrivateKey: .empty,
                    email: .empty,
                    displayName: .empty,
                    keys: .empty),
        salts: .empty,
        passphrases: [:],
        addresses: .empty,
        scopes: ["test_scope"]
    )

    init() {
        _ = Self.cryptoIsInstalled

        userManager.stubbedCurrentActiveUser = .init(nil)
        themeProvider.stubbedSharedPreferences = .init(.default)

        let symmetricKeyProvider = NonSendableSymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = SymmetricKey.random()

        authManager = AuthManager(keychain: InMemoryKeychainMock(),
                                  symmetricKeyProvider: symmetricKeyProvider,
                                  module: .hostApp,
                                  logManager: LogManagerProtocolMock())
        authManager.setUp()
    }

    @Test func `no credentials exist when no session is persisted`() {
        _ = makeSUT()

        #expect(authManager.getAllCurrentCredentials().isEmpty)
    }

    @Test func `the unauthenticated api service has no session`() {
        let sut = makeSUT()

        let apiService = sut.getUnauthApiService()

        #expect(apiService.sessionUID.isEmpty)
        #expect(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID) == nil)
    }

    @Test func `an existing user account gets its own api service`() async throws {
        try await givenActiveUserWithSession()
        let sut = makeSUT()

        let apiService = try sut.getApiService(userId: userData.user.ID)

        #expect(apiService.sessionUID == userData.credential.sessionID)
        #expect(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID)
            == Credential(userData.credential))
    }

    @Test func `invalidating a session removes its api service`() async throws {
        try await givenActiveUserWithSession()
        authManager.onSessionObtaining(credential: Credential(UID: "test_session_id2",
                                                              accessToken: "test_access_token2",
                                                              refreshToken: "test_refresh_token2",
                                                              userName: "test_user_name2",
                                                              userID: "test_user_id2",
                                                              scopes: [],
                                                              mailboxPassword: ""))
        let sut = makeSUT()

        let apiService = try sut.getApiService(userId: userData.user.ID)

        #expect(apiService.sessionUID == userData.credential.sessionID)
        #expect(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID)
            == Credential(userData.credential))

        authManager.onAuthenticatedSessionInvalidated(sessionUID: userData.credential.sessionID)

        #expect(throws: PassError.api(.noApiServiceLinkedToUserId)) {
            try sut.getApiService(userId: userData.user.ID)
        }
    }

    @Test func `invalidating the last session falls back to a new unauthenticated api service`() async throws {
        try await givenActiveUserWithSession()
        let sut = makeSUT()

        let apiService = try sut.getApiService(userId: userData.user.ID)

        #expect(apiService.sessionUID == userData.credential.sessionID)
        #expect(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID)
            == Credential(userData.credential))

        authManager.onAuthenticatedSessionInvalidated(sessionUID: userData.credential.sessionID)

        let unauthApiService = try sut.getApiService(userId: "")

        #expect(unauthApiService.sessionUID.isEmpty)
    }
}

private extension APIManagerTests {
    func makeSUT() -> APIManager {
        APIManager(authManager: authManager,
                   userManager: userManager,
                   themeProvider: themeProvider,
                   appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                   doh: ProtonPassDoHMock(),
                   logManager: LogManagerProtocolMock())
    }

    func givenActiveUserWithSession() async throws {
        try await userManager.setUp()
        authManager.onSessionObtaining(credential: Credential(userData.credential))
        try await userManager.upsertAndMarkAsActive(userData: userData)
        userManager.stubbedGetActiveUserDataResult = userData
        userManager.stubbedCurrentActiveUser = .init(userData)
    }
}
