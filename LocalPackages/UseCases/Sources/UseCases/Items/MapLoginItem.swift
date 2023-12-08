//
// MapLoginItem.swift
// Proton Pass - Created on 03/08/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import Entities

/// A login item can have multiple associated URLs while the OS expects a single URL per item,
/// so we need to make a separate entry for each URL in the credential database.
/// This use case map a login item into multiple `AutoFillCredential`
public protocol MapLoginItemUseCase: Sendable {
    func execute(for item: SymmetricallyEncryptedItem) throws -> [AutoFillCredential]
}

public extension MapLoginItemUseCase {
    func callAsFunction(for item: SymmetricallyEncryptedItem) throws -> [AutoFillCredential] {
        try execute(for: item)
    }
}

public final class MapLoginItem: Sendable, MapLoginItemUseCase {
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(symmetricKeyProvider: any SymmetricKeyProvider) {
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(for item: SymmetricallyEncryptedItem) throws -> [AutoFillCredential] {
        let itemContent = try item.getItemContent(symmetricKey: symmetricKeyProvider.getSymmetricKey())
        guard case let .login(data) = itemContent.contentData else {
            throw PassError.credentialProvider(.notLogInItem)
        }
        return data.urls.map { .init(shareId: itemContent.shareId,
                                     itemId: itemContent.item.itemID,
                                     username: data.username,
                                     url: $0,
                                     lastUseTime: itemContent.item.lastUseTime ?? 0) }
    }
}
