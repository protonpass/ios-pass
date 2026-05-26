//
// FolderFailureReason.swift
// Proton Pass - Created on 20/05/2026.
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

import Foundation

public extension PassError {
    enum FolderFailureReason: CustomDebugStringConvertible, Sendable {
        case layerFull(container: String, limit: Int)
        case depthExceeded(container: String, limit: Int)
        case vaultFull(container: String, limit: Int)

        public var debugDescription: String {
            switch self {
            case let .layerFull(containerName, limit):
                "\(containerName) has reached the limit of \(limit) sub-folders"
            case let .depthExceeded(containerName, limit):
                "\(containerName) cannot be nest more than \(limit) levels deep"
            case let .vaultFull(containerName, limit):
                "\(containerName) has reached the limit of \(limit) folders"
            }
        }
    }
}
