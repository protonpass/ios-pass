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
    static func random(id: String = .random(),
                       key: Data = .init(),
                       metadata: PendingFileAttachment.Metadata = .random()) -> Self {
        .init(id: id, key: key, metadata: metadata)
    }
}

public extension PendingFileAttachment.Metadata {
    static func random(url: URL = URL(string: "https://proton.me")!,
                       mimeType: String = .random(),
                       fileGroup: FileGroup = .document,
                       size: UInt64 = .random(in: 1...1_000),
                       formattedSize: String? = .random()) -> Self {
        .init(url: url,
              mimeType: mimeType,
              fileGroup: fileGroup,
              size: size,
              formattedSize: formattedSize)
    }
}
