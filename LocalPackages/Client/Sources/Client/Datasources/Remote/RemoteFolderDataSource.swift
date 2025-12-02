//  
// RemoteFolderDataSource.swift
// Proton Pass - Created on 02/12/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Entities
import Foundation

public protocol RemoteFolderDataSourceProtocol: Sendable {
    func getFolders(userId: String,
                    shareId: String,
                    sinceToken: String?,
                    pageSize: Int) async throws -> PaginatedFolders
    func getFolder(userId: String,
                   shareId: String,
                   folderId: String) async throws -> Folder
    func create(userId: String, shareId: String, request: CreateFolderRequest) async throws -> Folder
    func delete() async throws
    func update(userId: String, shareId: String, folderId: String, request: UpdateFolderRequest) async throws -> Folder
    func move(userId: String, shareId: String, folderId: String, request: MoveFolderRequest) async throws -> Folder
}

public extension RemoteFolderDataSourceProtocol {
    func getFolders(userId: String,
                    shareId: String,
                    sinceToken: String? = nil,
                    pageSize: Int = Constants.Utils.defaultPageSize) async throws -> PaginatedFolders {
       try await getFolders(userId: userId, shareId: shareId, sinceToken: sinceToken, pageSize: pageSize)
    }
}

public final class RemoteFolderDataSource: RemoteDatasource, RemoteFolderDataSourceProtocol, @unchecked Sendable {}

public extension RemoteFolderDataSource {
    func getFolders(userId: String,
                    shareId: String,
                    sinceToken: String?,
                    pageSize: Int) async throws -> PaginatedFolders {
        let endpoint = GetListOfFolderEndpoint(shareId: shareId, sinceToken: sinceToken, pageSize: pageSize)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.folders
    }
    
    func getFolder(userId: String,
                   shareId: String,
                   folderId: String) async throws -> Folder {
        let endpoint = GetFolderEndpoint(shareId: shareId, folderId: folderId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.folder
    }
    
    func create(userId: String, shareId: String, request: CreateFolderRequest) async throws -> Folder {
        let endpoint = CreateFolderEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.folder
    }
    
    func delete() async throws {}
    
    func update(userId: String, shareId: String, folderId: String, request: UpdateFolderRequest) async throws -> Folder {
        let endpoint = UpdateFolderEndpoint(shareId: shareId, folderId: folderId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.folder
    }
    
    func move(userId: String, shareId: String, folderId: String, request: MoveFolderRequest) async throws -> Folder {
        let endpoint = MoveFolderEndpoint(shareId: shareId, folderId: folderId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.folder
    }
}
