//
// CxpExport.swift
// Proton Pass - Created on 02/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import AuthenticationServices
import Client
import Entities
import Foundation
import PassRustCore
import UIKit

public protocol CxpExportUseCase: Sendable {
    @available(iOS 26.0, *)
    func callAsFunction(window: UIWindow, shares: [Entities.Share]) async throws
}

public struct CxpExport: CxpExportUseCase {
    private let userManager: any UserManagerProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let itemRepository: any ItemRepositoryProtocol
    private let cxfSerialization: any CxfSerializationProtocol
    private let passSerialization: any ProtonPassSerializationProtocol

    public init(userManager: any UserManagerProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                itemRepository: any ItemRepositoryProtocol,
                cxfSerialization: any CxfSerializationProtocol = CxfSerialization(),
                passSerialization: any ProtonPassSerializationProtocol = ProtonPassSerialization()) {
        self.userManager = userManager
        self.symmetricKeyProvider = symmetricKeyProvider
        self.itemRepository = itemRepository
        self.cxfSerialization = cxfSerialization
        self.passSerialization = passSerialization
    }

    @available(iOS 26.0, *)
    public func callAsFunction(window: UIWindow, shares: [Entities.Share]) async throws {
        let manager = ASCredentialExportManager(presentationAnchor: window)
        let exportOptions = try await manager.requestExport()
        guard exportOptions.formatVersion == .v1 else {
            throw PassError.unsupportedCxfVersion(exportOptions.formatVersion.rawValue)
        }
        let data = try await exportedCredentialData(shares: shares)
        try await manager.exportCredentials(data)
    }
}

private extension CxpExport {
    /// Decrypts and serializes every exported item, so keep it off the main actor
    @available(iOS 26.0, *)
    @concurrent
    func exportedCredentialData(shares: [Entities.Share]) async throws -> ASExportedCredentialData {
        let userId = try await userManager.getActiveUserId()
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let itemsByShareId = try await Dictionary(grouping: itemRepository.getItems(userId: userId,
                                                                                    state: .active),
                                                  by: \.shareId)

        let vaults: [CxfVaultWithItems] = try shares.compactMap { share in
            guard let vaultContent = share.vaultContent else { return nil }
            let items = try (itemsByShareId[share.shareId] ?? []).map { encryptedItem in
                let content = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                let item = try passSerialization.itemDataDeserialize(data: content.protobuf.data())
                return ItemWithMetadata(item: item,
                                        metadata: .init(createdAt: UInt64(clamping: content.item.createTime),
                                                        modifiedAt: UInt64(clamping: content.item.modifyTime),
                                                        pinned: content.item.pinned))
            }
            let vault = try passSerialization.vaultDataDeserialize(data: vaultContent.serializedData())
            return CxfVaultWithItems(vault: vault, items: items)
        }

        let input = CxfExportInput(vaults: vaults,
                                   exporterRpId: "proton.me",
                                   exporterDisplayName: "Proton Pass",
                                   timestamp: UInt64(Date.now.timeIntervalSince1970))
        let payload = try cxfSerialization.export(input: input).payload
        return try JSONDecoder.cxf.decode(ASExportedCredentialData.self, from: Data(payload.utf8))
    }
}
