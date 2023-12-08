//
// AliasRepository.swift
// Proton Pass - Created on 14/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import CoreData
import Entities
import ProtonCoreNetworking
import ProtonCoreServices

public protocol AliasRepositoryProtocol: Sendable {
    func getAliasOptions(shareId: String) async throws -> AliasOptions
    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias
    @discardableResult
    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias
}

public actor AliasRepository: AliasRepositoryProtocol {
    private let remoteDatasouce: any RemoteAliasDatasourceProtocol

    public init(remoteDatasouce: any RemoteAliasDatasourceProtocol) {
        self.remoteDatasouce = remoteDatasouce
    }
}

public extension AliasRepository {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        try await remoteDatasouce.getAliasOptions(shareId: shareId)
    }

    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias {
        try await remoteDatasouce.getAliasDetails(shareId: shareId, itemId: itemId)
    }

    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias {
        try await remoteDatasouce.changeMailboxes(shareId: shareId, itemId: itemId, mailboxIDs: mailboxIDs)
    }
}
