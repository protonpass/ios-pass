//
// SessionManager.swift
// Proton Pass - Created on 12/06/2024.
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
//

import Combine
import Core
import Entities
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking

public protocol SessionManagerProtocol {
    /// Hold the list of all logged in users
    var userDatas: CurrentValueSubject<[UserData], Never> { get }

    /// Set up the manager by loading what we have locally into memory
    func setUp() async throws

    /// The `UserData` of the active user
    func getActiveUserData() throws -> UserData?

    /// Get the credential of the active user if any, fallback to unauth credential if not exist
    func getCredential() async throws -> AuthCredential?

    /// Upsert the updated credential. We make the difference between auth and unauth credential
    /// at the implementation level
    func upsert(credential: AuthCredential) async throws

    /// Should be called when logging the user out manually
    /// or forcefully (e.g the session is invalidated after password changes)
    /// to clean up associated credentials
    func removeAllCredentials(userId: String) async throws
}

public final class SessionManager: SessionManagerProtocol {
    private let authDatasource: any LocalAuthCredentialDatasourceProtocol
    private let unauthDatasource: any LocalUnauthCredentialDatasourceProtocol
    private let preferencesManager: any PreferencesManagerProtocol
    private let module: PassModule
    private let logger: Logger

    public let userDatas: CurrentValueSubject<[UserData], Never> = .init([])

    private var didSetUp = false

    init(authDatasource: any LocalAuthCredentialDatasourceProtocol,
         unauthDatasource: any LocalUnauthCredentialDatasourceProtocol,
         preferencesManager: any PreferencesManagerProtocol,
         module: PassModule,
         logManager: any LogManagerProtocol) {
        self.module = module
        self.authDatasource = authDatasource
        self.unauthDatasource = unauthDatasource
        self.preferencesManager = preferencesManager
        logger = .init(manager: logManager)
    }
}

public extension SessionManager {
    func setUp() async throws {
        didSetUp = true
    }

    func getActiveUserData() throws -> UserData? {
        assertDidSetUp()
        guard let activeUserId = getActiveUserId() else {
            return nil
        }
        guard let activeUser = userDatas.value.first(where: { $0.user.ID == activeUserId }) else {
            assertionFailure("Active user ID found but no corresponding UserData")
            return nil
        }
        return activeUser
    }

    func getCredential() async throws -> AuthCredential? {
        assertDidSetUp()
        if let activeUserId = getActiveUserId() {
            return try await authDatasource.getCredential(userId: activeUserId,
                                                          module: module)
        } else {
            return try unauthDatasource.getUnauthCredential()
        }
    }

    func upsert(credential: AuthCredential) async throws {
        assertDidSetUp()
        if credential.userID.isEmpty {
            try unauthDatasource.upsertUnauthCredential(credential)
        } else {
            guard let activeUserId = getActiveUserId() else {
                assertionFailure("Try to upsert credential but no active user ID found")
                return
            }
            try await authDatasource.upsertCredential(userId: activeUserId,
                                                      credential: credential,
                                                      module: module)
        }
    }

    func removeAllCredentials(userId: String) async throws {
        assertDidSetUp()
        try await authDatasource.removeAllCredentials(userId: userId)
    }
}

private extension SessionManager {
    func assertDidSetUp() {
        assert(didSetUp, "SessionManager not set up. Call setUp() function as soon as possible.")
        if !didSetUp {
            logger.error("SessionManager not set up")
        }
    }

    func getActiveUserId() -> String? {
        preferencesManager.appPreferences.unwrapped().activeUserId
    }
}
