//
// ItemFile+Mock.swift
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

public extension ItemFile {
    static func random(fileID: String,
                       size: Int = .random(in: 1...1_000),
                       metadata: String? = nil,
                       fileKey: String? = nil,
                       itemKeyRotation: Int = .random(in: 1...1_000),
                       chunks: [FileChunk] = [],
                       revisionAdded: Int = .random(in: 1...1_000),
                       revisionRemoved: Int = .random(in: 1...1_000),
                       createTime: Int = .random(in: 1...1_000),
                       modifyTime: Int = .random(in: 1...1_000)) -> Self {
        .init(fileID: fileID,
              size: size,
              metadata: metadata ?? .random(),
              fileKey: fileKey ?? .random(),
              itemKeyRotation: itemKeyRotation,
              chunks: chunks,
              revisionAdded: revisionAdded,
              revisionRemoved: revisionRemoved,
              createTime: createTime,
              modifyTime: modifyTime)
    }
}
