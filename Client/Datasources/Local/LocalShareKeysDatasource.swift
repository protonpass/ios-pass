//
// LocalShareKeysDatasource.swift
// Proton Pass - Created on 16/08/2022.
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

public protocol LocalShareKeysDatasourceProtocol {
    func getShareKeys(shareId: String, page: Int, pageSize: Int) async throws -> ShareKeys
}

public final class LocalShareKeysDatasource {
    let localItemKeyDatasource: LocalItemKeyDatasourceProtocol
    let localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol

    public init(localItemKeyDatasource: LocalItemKeyDatasourceProtocol,
                localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol) {
        self.localItemKeyDatasource = localItemKeyDatasource
        self.localVaultKeyDatasource = localVaultKeyDatasource
    }
}

extension LocalShareKeysDatasource: LocalShareKeysDatasourceProtocol {
    public func getShareKeys(shareId: String, page: Int, pageSize: Int) async throws -> ShareKeys {
        let itemKeyCount = try await localItemKeyDatasource.getItemKeyCount(shareId: shareId)
        let vaultKeyCount = try await localVaultKeyDatasource.getVaultKeyCount(shareId: shareId)
        guard itemKeyCount == vaultKeyCount else {
            throw LocalDatasourceError.corruptedShareKeys(shareId: shareId,
                                                          itemKeyCount: itemKeyCount,
                                                          vaultKeyCount: vaultKeyCount)
        }

        let itemKeys = try await localItemKeyDatasource.getItemKeys(shareId: shareId,
                                                                    page: page,
                                                                    pageSize: pageSize)
        let vaultKeys = try await localVaultKeyDatasource.getVaultKeys(shareId: shareId,
                                                                       page: page,
                                                                       pageSize: pageSize)
        return .init(vaultKeys: vaultKeys, itemKeys: itemKeys, total: itemKeyCount)
    }
}
