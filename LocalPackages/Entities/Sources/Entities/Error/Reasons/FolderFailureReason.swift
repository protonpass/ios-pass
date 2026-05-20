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
        case layerFull
        case depthExceeded
        case vaultFull

        public var debugDescription: String {
            switch self {
            case .layerFull:
                "Destination folder already contains \(FolderLimits.maxFoldersPerLayer) folders"
            case .depthExceeded:
                "Folders cannot be nested more than \(FolderLimits.maxFolderDepth) levels deep"
            case .vaultFull:
                "Vault already contains the maximum of \(FolderLimits.maxFoldersPerVault) folders"
            }
        }
    }
}
