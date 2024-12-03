//
// LoadVaultDatas.swift
// Proton Pass - Created on 28/10/2024.
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

import Client
import Core
@preconcurrency import CryptoKit
import Entities

private struct Batch: Sendable {
    let dict: [String: [ItemUiModel]] // ShareID -> ItemUiModel
    let trashed: [ItemUiModel]
}

public protocol LoadVaultDatasUseCase: Sendable {
    func execute(symmetricKey: SymmetricKey,
                 vaults: [Share],
                 items: [SymmetricallyEncryptedItem]) async throws -> VaultDatasUiModel
}

public extension LoadVaultDatasUseCase {
    func callAsFunction(symmetricKey: SymmetricKey,
                        vaults: [Share],
                        items: [SymmetricallyEncryptedItem]) async throws -> VaultDatasUiModel {
        try await execute(symmetricKey: symmetricKey, vaults: vaults, items: items)
    }
}

public final class LoadVaultDatas: LoadVaultDatasUseCase {
    public init() {}

    public func execute(symmetricKey: SymmetricKey,
                        vaults: [Share],
                        items: [SymmetricallyEncryptedItem]) async throws -> VaultDatasUiModel {
        let batches = try await withThrowingTaskGroup(of: Batch.self,
                                                      returning: [Batch].self) { @Sendable group in
            let itemBatches = items.chunked(into: Constants.Utils.batchSize)
            for batch in itemBatches {
                group.addTask { @Sendable in
                    var dict = [String: [ItemUiModel]]()
                    var trashed = [ItemUiModel]()
                    for item in batch {
                        let uiModel = try item.toItemUiModel(symmetricKey)
                        guard uiModel.state == .active else {
                            trashed.append(uiModel)
                            continue
                        }
                        if dict[item.shareId] == nil {
                            dict[item.shareId] = []
                        }
                        dict[item.shareId]?.append(uiModel)
                    }
                    return Batch(dict: dict, trashed: trashed)
                }
            }

            var results = [Batch]()
            for try await result in group {
                results.append(result)
            }
            return results
        }

        // ShareID -> ItemUiModel
        var vaultDict = Dictionary(uniqueKeysWithValues: vaults.map { ($0.id, [ItemUiModel]()) })
        var trashedItems = [ItemUiModel]()

        for batch in batches {
            for (shareId, items) in batch.dict {
                if vaultDict[shareId] == nil {
                    vaultDict[shareId] = []
                }
                vaultDict[shareId]?.append(contentsOf: items)
            }
            trashedItems.append(contentsOf: batch.trashed)
        }

        let vaultContentUiModels = vaults
            .compactMap { vault -> VaultContentUiModel? in
                guard let items = vaultDict[vault.shareId] else {
                    assertionFailure("Items for share \(vault.shareId) should not be nil")
                    return nil
                }
                return .init(vault: vault, items: items)
            }

        return .init(vaults: vaultContentUiModels, trashedItems: trashedItems)
    }
}
