//
// PendingFileAttachment+Mock.swift
// Proton Pass - Created on 13/12/2024.
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

import Entities
import Foundation

public extension PendingFileAttachment {
    static func random(id: String? = nil,
                       key: Data = .init(),
                       metadata: PendingFileAttachment.Metadata = .random(),
                       chunkCount: Int = .random(in: 1...1_000),
                       encryptionVersion: Int = .random(in: 1...1_000)) -> Self {
        .init(id: id ?? .random(),
              key: key,
              metadata: metadata,
              chunkCount: chunkCount,
              encryptionVersion: encryptionVersion)
    }
}

public extension PendingFileAttachment.Metadata {
    static func random(url: URL = URL(string: "https://proton.me")!,
                       mimeType: String? = nil,
                       fileGroup: FileGroup = .document,
                       size: UInt64 = .random(in: 1...1_000),
                       formattedSize: String? = nil) -> Self {
        .init(url: url,
              mimeType: mimeType ?? .random(),
              fileGroup: fileGroup,
              size: size,
              formattedSize: formattedSize ?? .random())
    }
}
