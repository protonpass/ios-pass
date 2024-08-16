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

import Combine
import Core
import CoreMocks
import ClientMocks
import Entities
import Factory
@testable import Client
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreAuthentication
import ProtonCoreTestingToolkitUnitTestsCore
import CryptoKit
import XCTest
import ProtonCoreDoh
import ProtonCoreCryptoGoImplementation
import Foundation

enum KeychainError: Error {
    case dataConversionError
    case stringConversionError
    case unexpectedError
}

final class UserDefaultsKeychainMock: KeychainProtocol {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func dataOrError(forKey key: String, attributes: [CFString: Any]?) throws -> Data? {
        guard let data = userDefaults.data(forKey: key) else {
            throw KeychainError.unexpectedError
        }
        return data
    }

    func stringOrError(forKey key: String, attributes: [CFString: Any]?) throws -> String? {
        guard let string = userDefaults.string(forKey: key) else {
            throw KeychainError.unexpectedError
        }
        return string
    }

    func setOrError(_ data: Data, forKey key: String, attributes: [CFString: Any]?) throws {
        userDefaults.set(data, forKey: key)
    }

    func setOrError(_ string: String, forKey key: String, attributes: [CFString: Any]?) throws {
        userDefaults.set(string, forKey: key)
    }

    func removeOrError(forKey key: String) throws {
        userDefaults.removeObject(forKey: key)
    }
}

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
        signupDomain =  "proton.me"
        captchaHost = "https://pass-api.proton.me"
        humanVerificationV3Host = "https://verify.proton.me"
        accountHost = "https://account.proton.me"
        defaultHost = "https://pass-api.proton.me"
        apiHost = "pass-api.proton.me"
        defaultPath = "/api"
        proxyToken = nil
    }
}

final class APIManagerTests: XCTestCase {
    private var sessionPublisher: AnyCancellable?
    let key = SymmetricKey.random()
    let mock = NonSendableSymmetricKeyProviderMock()
    var userManager: UserManagerProtocolMock!
    var sut: APIManager!
    var authManager: AuthManagerProtocol!
    var stubbedCurrentActiveUser: CurrentValueSubject<UserData?, Never>!
    let userDefaultsKeychainMock =  UserDefaultsKeychainMock()

    override func setUp() {
        super.setUp()
        injectDefaultCryptoImplementation()

        userManager = .init()
        stubbedCurrentActiveUser = .init(nil)
        userManager.stubbedCurrentActiveUser = stubbedCurrentActiveUser
        mock.stubbedGetSymmetricKeyResult = key

        authManager = AuthManager(keychain: userDefaultsKeychainMock,
                                  symmetricKeyProvider: mock,
                                  module: .hostApp,
                                  logManager: LogManagerProtocolMock())
    }

    override func tearDown() {
        sut = nil
        authManager = nil
        try? userDefaultsKeychainMock.removeOrError(forKey: AuthManager.storageKey)
        sessionPublisher?.cancel()
        super.tearDown()
    }

    let unauthSessionCredentials =  Credential(UID: "",
                                               accessToken: "test_access_token_unauth",
                                               refreshToken: "test_refresh_token_unauth",
                                               userName: "",
                                               userID: "",
                                               scopes: [],
                                               mailboxPassword: "")

    let userData = UserData(
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

    func testAPIServiceIsCreatedWithoutSessionIfNoSessionIsPersisted() throws {
        sut = APIManager(authManager: authManager,
                         userManager: userManager,
                         themeProvider: ThemeProviderMock(),
                         appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                         doh: ProtonPassDoHMock(),
                         logManager: LogManagerProtocolMock())
       
        let credentials = authManager.getAllCurrentCredentials()

        // THEN
        XCTAssertTrue(credentials.isEmpty)
    }
    
    func testApiManger_ShouldCreateNewUnauthAPIService_ShouldSucceed() {
        // Given
        sut = APIManager(authManager: authManager,
                         userManager: userManager,
                         themeProvider: ThemeProviderMock(),
                         appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                         doh: ProtonPassDoHMock(),
                         logManager: LogManagerProtocolMock())
        
        let apiService = sut.getUnauthApiService()
        
        // Then
        XCTAssertTrue(apiService.sessionUID.isEmpty)
        XCTAssertTrue(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID) == nil)

    }
    
        func  testApiManger_WhenUserAccountExist_ShouldHaveApiServiceForUser() async throws {
            // GIVEN
            try await userManager.setUp()
            authManager.onSessionObtaining(credential: Credential(userData.credential))
            try await userManager.upsertAndMarkAsActive(userData: userData)
            stubbedCurrentActiveUser = .init(userData)
            userManager.stubbedGetActiveUserDataResult = userData
            userManager.stubbedCurrentActiveUser = stubbedCurrentActiveUser
    
            // WHEN
            sut = APIManager(authManager: authManager,
                             userManager: userManager,
                             themeProvider: ThemeProviderMock(),
                             appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                             doh: ProtonPassDoHMock(),
                             logManager: LogManagerProtocolMock())
    
            let apiService = try sut.getApiService(userId: userData.user.ID)
           
            XCTAssertEqual(apiService.sessionUID, userData.credential.sessionID)
            XCTAssertEqual(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID), Credential(userData.credential))
        }
    
    func  testApiManger_WithExpiredSession_ShouldRemoveLinkedAPIService() async throws {
        // GIVEN
        try await userManager.setUp()
        authManager.onSessionObtaining(credential: Credential(userData.credential))
        authManager.onSessionObtaining(credential: Credential(UID: "test_session_id2",
                                                              accessToken: "test_access_token2",
                                                              refreshToken: "test_refresh_token2",
                                                              userName: "test_user_name2",
                                                              userID: "test_user_id2",
                                                              scopes: [],
                                                              mailboxPassword: ""))

        try await userManager.upsertAndMarkAsActive(userData: userData)
        stubbedCurrentActiveUser = .init(userData)
        userManager.stubbedGetActiveUserDataResult = userData
        userManager.stubbedCurrentActiveUser = stubbedCurrentActiveUser

        // WHEN
        sut = APIManager(authManager: authManager,
                         userManager: userManager,
                         themeProvider: ThemeProviderMock(),
                         appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                         doh: ProtonPassDoHMock(),
                         logManager: LogManagerProtocolMock())

        let apiService = try sut.getApiService(userId: userData.user.ID)
       
        XCTAssertEqual(apiService.sessionUID, userData.credential.sessionID)
        XCTAssertEqual(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID), Credential(userData.credential))
        
        authManager.onAuthenticatedSessionInvalidated(sessionUID: userData.credential.sessionID)
        
        XCTAssertThrowsError(
            try sut.getApiService(userId: userData.user.ID)
          ) { error in
              if case let PassError.api(reason) = error {
                  XCTAssertEqual(
                    reason, .noApiServiceLinkedToUserId
                  )
              } else {
                  XCTFail("Should return noApiServiceLinkedToUserId api error reason")
              }
          }
    }
    
    func testApiManger_WithLastSessionExpire_ShouldCreateANewUnauthSession() async throws {
        // GIVEN
        try await userManager.setUp()
        authManager.onSessionObtaining(credential: Credential(userData.credential))
        try await userManager.upsertAndMarkAsActive(userData: userData)
        stubbedCurrentActiveUser = .init(userData)
        userManager.stubbedGetActiveUserDataResult = userData
        userManager.stubbedCurrentActiveUser = stubbedCurrentActiveUser

        // WHEN
        sut = APIManager(authManager: authManager,
                         userManager: userManager,
                         themeProvider: ThemeProviderMock(),
                         appVersion: "ios-pass@\(Bundle.main.fullAppVersionName)",
                         doh: ProtonPassDoHMock(),
                         logManager: LogManagerProtocolMock())

        let apiService = try sut.getApiService(userId: userData.user.ID)
       
        XCTAssertEqual(apiService.sessionUID, userData.credential.sessionID)
        XCTAssertEqual(apiService.authDelegate?.credential(sessionUID: apiService.sessionUID), Credential(userData.credential))
        
        authManager.onAuthenticatedSessionInvalidated(sessionUID: userData.credential.sessionID)
        
        let unauthApiService = try sut.getApiService(userId: "")
        
        XCTAssertTrue(unauthApiService.sessionUID.isEmpty)
    }
}
