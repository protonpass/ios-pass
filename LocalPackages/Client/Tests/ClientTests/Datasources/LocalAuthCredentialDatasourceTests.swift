//
// LocalAuthCredentialDatasourceTests.swift
// Proton Pass - Created on 16/05/2024.
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

@testable import Client
import Entities
import ProtonCoreNetworking
import XCTest

final class LocalAuthCredentialDatasourceTests: XCTestCase {
    var sut: LocalAuthCredentialDatasourceProtocol!

    override func setUp() {
        super.setUp()
        let factory = SymmetricKeyProviderMockFactory()
        factory.setUp()
        sut = LocalAuthCredentialDatasource(symmetricKeyProvider: factory.getProvider(),
                                            databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalAuthCredentialDatasourceTests {
    func testUpsertAndGetCredential() async throws {
        // Given
        let userId1 = String.random()
        let finalHostAppCredential1 = AuthCredential.random()
        let finalAutofillCredential1 = AuthCredential.random()
        let finalShareAppCredential1 = AuthCredential.random()

        let userId2 = String.random()
        let finalHostAppCredential2 = AuthCredential.random()
        let finalAutofillCredential2 = AuthCredential.random()
        let finalShareAppCredential2 = AuthCredential.random()

        // Simulate multiple updates
        for _ in 0..<Int.random(in: 5...10) {
            try await upsert(userId: userId1, 
                             cred: .random(),
                             module: .hostApp)
            try await upsert(userId: userId1,
                             cred: .random(),
                             module: .autoFillExtension)
            try await upsert(userId: userId1, 
                             cred: .random(),
                             module: .shareExtension)

            try await upsert(userId: userId2,
                             cred: .random(),
                             module: .hostApp)
            try await upsert(userId: userId2,
                             cred: .random(),
                             module: .autoFillExtension)
            try await upsert(userId: userId2, 
                             cred: .random(),
                             module: .shareExtension)
        }

        // When
        try await upsert(userId: userId1,
                         cred: finalHostAppCredential1, module: .hostApp)

        try await upsert(userId: userId1,
                         cred: finalAutofillCredential1,
                         module: .autoFillExtension)

        try await upsert(userId: userId1,
                         cred: finalShareAppCredential1,
                         module: .shareExtension)

        try await upsert(userId: userId2,
                         cred: finalHostAppCredential2,
                         module: .hostApp)

        try await upsert(userId: userId2,
                         cred: finalAutofillCredential2,
                         module: .autoFillExtension)

        try await upsert(userId: userId2,
                         cred: finalShareAppCredential2,
                         module: .shareExtension)

        // Then
        try await getAndAssertEqual(userId: userId1,
                                    module: .hostApp,
                                    otherCred: finalHostAppCredential1)
        try await getAndAssertEqual(userId: userId1,
                                    module: .autoFillExtension,
                                    otherCred: finalAutofillCredential1)
        try await getAndAssertEqual(userId: userId1,
                                    module: .shareExtension,
                                    otherCred: finalShareAppCredential1)

        try await getAndAssertEqual(userId: userId2,
                                    module: .hostApp,
                                    otherCred: finalHostAppCredential2)
        try await getAndAssertEqual(userId: userId2,
                                    module: .autoFillExtension,
                                    otherCred: finalAutofillCredential2)
        try await getAndAssertEqual(userId: userId2,
                                    module: .shareExtension,
                                    otherCred: finalShareAppCredential2)

        // When
        try await sut.removeAllCredentials(userId: userId1)

        // Then
        try await getAndAssertEqual(userId: userId1,
                                    module: .hostApp,
                                    otherCred: nil)
        try await getAndAssertEqual(userId: userId1,
                                    module: .autoFillExtension,
                                    otherCred: nil)
        try await getAndAssertEqual(userId: userId1,
                                    module: .shareExtension,
                                    otherCred: nil)

        try await getAndAssertEqual(userId: userId2,
                                    module: .hostApp,
                                    otherCred: finalHostAppCredential2)
        try await getAndAssertEqual(userId: userId2,
                                    module: .autoFillExtension,
                                    otherCred: finalAutofillCredential2)
        try await getAndAssertEqual(userId: userId2,
                                    module: .shareExtension,
                                    otherCred: finalShareAppCredential2)
    }

    func upsert(userId: String, cred: AuthCredential, module: PassModule) async throws {
        try await sut.upsertCredential(userId: userId,
                                       credential: cred,
                                       module: module)
    }

    func getAndAssertEqual(userId: String,
                           module: PassModule,
                           otherCred: AuthCredential?) async throws {
        let result = try await sut.getCredential(userId: userId, module: module)
        if let otherCred {
            let unwrapped = try XCTUnwrap(result)
            XCTAssertTrue(unwrapped.isEqual(to: otherCred))
        } else {
            XCTAssertNil(result)
        }
    }
}
