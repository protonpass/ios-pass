//
// Item+Extensions.swift
// Proton Pass - Created on 24/11/2023.
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

import CryptoKit
import Entities
import Foundation
import ProtonCoreDataModel
import ProtonCoreLogin

public extension Item {
    func getContentProtobuf(shareKey: any ShareKeyProtocol,
                            shouldDecryptKey: Bool = true) throws -> ItemContentProtobuf {
        guard shareKey.keyRotation == keyRotation else {
            throw PassError.crypto(.unmatchedKeyRotation(lhsKey: shareKey.keyRotation,
                                                         rhsKey: keyRotation))
        }

        guard let contentData = try content.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }
        
        let decryptionKey: Data
        if let itemKey, shouldDecryptKey {
            guard let itemKeyData = try itemKey.base64Decode() else {
                throw PassError.crypto(.failedToBase64Decode)
            }
            decryptionKey = try AES.GCM.open(itemKeyData,
                                             key: shareKey.keyData,
                                             associatedData: .itemKey)
        } else {
            decryptionKey = shareKey.keyData
        }

        let decryptedContentData = try AES.GCM.open(contentData,
                                                    key: decryptionKey,
                                                    associatedData: .itemContent)

        return try ItemContentProtobuf(data: decryptedContentData)
    }
}
