//
// LocalAuthCredentialDatasource.swift
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

import CoreData
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

// sourcery: AutoMockable
public protocol LocalAuthCredentialDatasourceProtocol: Sendable {
    func getCredential(userId: String, module: PassModule) async throws -> AuthCredential?
    func upsertCredential(userId: String,
                          credential: AuthCredential,
                          module: PassModule) async throws
    func removeAllCredentials(userId: String) async throws
}

public final class LocalAuthCredentialDatasource: LocalDatasource, LocalAuthCredentialDatasourceProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                databaseService: any DatabaseServiceProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        super.init(databaseService: databaseService)
    }
}

public extension LocalAuthCredentialDatasource {
    func getCredential(userId: String, module: PassModule) async throws -> AuthCredential? {
        let context = newTaskContext(type: .fetch)
        let request = AuthCredentialEntity.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "module = %@", module.rawValue)
        ])
        let credentials = try await execute(fetchRequest: request, context: context)
        assert(credentials.count <= 1, "Max 1 credential per user id and per type")
        let key = try await symmetricKeyProvider.getSymmetricKey()
        return try credentials.first.map { try $0.toAuthCredential(key) }
    }

    func upsertCredential(userId: String,
                          credential: AuthCredential,
                          module: PassModule) async throws {
        let key = try await symmetricKeyProvider.getSymmetricKey()

        try await upsertElements(items: [credential],
                                 fetchPredicate: NSPredicate(format: "userID == %@ AND module == %@", userId,
                                                             module.rawValue),
                                 itemComparisonKey: { _ in
                                     AuthCredentialKeyComparison(userId: userId, module: module.rawValue)
                                 },
                                 entityComparisonKey: { entity in
                                     AuthCredentialKeyComparison(userId: entity.userID, module: entity.module)
                                 },
                                 updateEntity: { (entity: AuthCredentialEntity, item: AuthCredential) in
                                     try entity.hydrate(userId: userId,
                                                         authCredential: item,
                                                         module: module,
                                                         key: key)
                                 },
                                 insertItems: { [weak self] credentials in
                                     guard let self else { return }
                                     try await insertCredential(userId: userId, 
                                                                credentials: credentials,
                                                                module: module, 
                                                                key: key)
                                 })
    }

    func removeAllCredentials(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "AuthCredentialEntity")
        request.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: request),
                          context: context)
    }
}

private extension LocalAuthCredentialDatasource {
    struct AuthCredentialKeyComparison: Hashable {
        let userId: String
        let module: String
    }

    func insertCredential(userId: String,
                          credentials: [AuthCredential],
                          module: PassModule,
                          key: SymmetricKey) async throws {
        let context = newTaskContext(type: .insert)
        var hydrationError: (any Error)?
        let request =
            newBatchInsertRequest(entity: AuthCredentialEntity.entity(context: context),
                                  sourceItems: credentials) { managedObject, credential in
                do {
                    try (managedObject as? AuthCredentialEntity)?.hydrate(userId: userId,
                                                                          authCredential: credential,
                                                                          module: module,
                                                                          key: key)
                } catch {
                    hydrationError = error
                }
            }
        if let hydrationError {
            throw hydrationError
        }
        try await execute(batchInsertRequest: request, context: context)
    }
}
