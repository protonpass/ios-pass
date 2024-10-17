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

public final class LocalAuthCredentialDatasource: LocalDatasource, LocalAuthCredentialDatasourceProtocol,
    @unchecked Sendable {
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
        try await upsert([credential],
                         entityType: AuthCredentialEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@ AND module == %@",
                                                     userId,
                                                     module.rawValue),
                         isEqual: { item, entity in
                             item.userID == entity.userID && module.rawValue == entity.module
                         },
                         hydrate: { _, entity in
                             try entity.hydrate(userId: userId,
                                                authCredential: credential,
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
