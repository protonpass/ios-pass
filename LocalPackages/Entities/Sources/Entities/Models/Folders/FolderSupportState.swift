//
// FolderSupportState.swift
// Proton Pass - Created on 17/09/2026.
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

import Foundation

public enum FolderSupportState: Sendable {
    /// Flag is not enabled
    case notSupported
    /// Flag is enabled but plan doesn't and upsell is needed (e.g free users)
    case supportedButShouldUpsell
    /// Flag is enabled and plan fully allows
    case supportedAndAllowed
    /// Flag is enabled but plan doesn't allow (e.g Pass Essentials)
    case supportedButNotAllowed

    public init(flagEnabled: Bool, plan: Plan?) {
        guard flagEnabled, let plan else {
            self = .notSupported
            return
        }
        self = if plan.folderAllowed {
            .supportedAndAllowed
        } else if plan.shouldUpsell {
            .supportedButShouldUpsell
        } else {
            .supportedButNotAllowed
        }
    }

    public var canCreateAndModifyFolders: Bool {
        if case .supportedAndAllowed = self {
            true
        } else {
            false
        }
    }

    public var isSupported: Bool {
        if case .notSupported = self {
            false
        } else {
            true
        }
    }

    public var shouldUpsell: Bool {
        if case .supportedButShouldUpsell = self {
            true
        } else {
            false
        }
    }
}
