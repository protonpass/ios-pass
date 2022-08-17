//
// GlobalLocalDatasource.swift
// Proton Pass - Created on 17/08/2022.
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

import CoreData

public protocol GlobalLocalDatasourceProtocol {
    var localShareDatasource: LocalShareDatasourceProtocol { get }
    var localItemKeyDatasource: LocalItemKeyDatasourceProtocol { get }
    var localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol { get }
    var localItemRevisionDatasource: LocalItemRevisionDatasourceProtocol { get }

    func removeAllData(userId: String) async throws
}

public extension GlobalLocalDatasourceProtocol {
    func removeAllData(userId: String) async throws {
        let shares = try await localShareDatasource.getAllShares(userId: userId)

        for share in shares {
            let shareId = share.shareID
            try await localItemRevisionDatasource.removeAllItemRevisions(shareId: shareId)
            try await localVaultKeyDatasource.removeAllVaultKeys(shareId: shareId)
            try await localItemKeyDatasource.removeAllItemKeys(shareId: shareId)
        }

        try await localShareDatasource.removeAllShares(userId: userId)
    }
}

/// Do we want to wipe everything when switching user?
/// Or we only want to do it only when logging out?
/// Not sure if this struct is useful
struct GlobalLocalDatasource: GlobalLocalDatasourceProtocol {
    let localShareDatasource: LocalShareDatasourceProtocol
    let localItemKeyDatasource: LocalItemKeyDatasourceProtocol
    let localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol
    let localItemRevisionDatasource: LocalItemRevisionDatasourceProtocol

    init(container: NSPersistentContainer) {
        self.localShareDatasource = LocalShareDatasource(container: container)
        self.localItemKeyDatasource = LocalItemKeyDatasource(container: container)
        self.localVaultKeyDatasource = LocalVaultKeyDatasource(container: container)
        self.localItemRevisionDatasource = LocalItemRevisionDatasource(container: container)
    }
}
