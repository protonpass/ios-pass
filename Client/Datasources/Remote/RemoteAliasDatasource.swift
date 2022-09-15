//
// RemoteAliasDatasource.swift
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

import Foundation

public protocol RemoteAliasDatasourceProtocol: BaseRemoteDatasourceProtocol {
    func getAliasOptions(shareId: String) async throws -> AliasOptions
    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias
    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias
}

public extension RemoteAliasDatasourceProtocol {
    func getAliasOptions(shareId: String) async throws -> AliasOptions {
        let endpoint = GetAliasOptionsEndpoint(credential: authCredential,
                                               shareId: shareId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.options
    }

    func getAliasDetails(shareId: String, itemId: String) async throws -> Alias {
        let endpoint = GetAliasDetailsEndpoint(credential: authCredential,
                                               shareId: shareId,
                                               itemId: itemId)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.alias
    }

    func changeMailboxes(shareId: String, itemId: String, mailboxIDs: [Int]) async throws -> Alias {
        let endpoint = ChangeMailboxesEndpoint(credential: authCredential,
                                               shareId: shareId,
                                               itemId: itemId,
                                               mailboxIDs: mailboxIDs)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.alias
    }
}

public final class RemoteAliasDatasource: BaseRemoteDatasource {}

extension RemoteAliasDatasource: RemoteAliasDatasourceProtocol {}
