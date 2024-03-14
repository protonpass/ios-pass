//
// Organization.swift
// Proton Pass - Created on 07/03/2024.
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

import Foundation

public struct Organization: Sendable, Decodable {
    /// Whether this user can update the organization
    public let canUpdate: Bool
    public let settings: Settings

    public init(canUpdate: Bool, settings: Settings) {
        self.canUpdate = canUpdate
        self.settings = settings
    }
}

public extension Organization {
    enum ShareMode: Int, Sendable, Decodable {
        /// Able to share within and outside of organization
        case unrestricted = 0

        /// Only share within organization
        case restricted = 1

        public static var `default`: Self { .restricted }
    }

    enum ExportMode: Int, Sendable, Decodable {
        /// Anyone can export data
        case anyone = 0

        /// Only admins can export data
        case admins = 1

        public static var `default`: Self { .admins }
    }

    struct Settings: Sendable, Decodable {
        public let shareMode: ShareMode

        /// 0 means lock time is not enforced
        public let forceLockSeconds: Int

        public let exportMode: ExportMode

        public init(shareMode: ShareMode,
                    forceLockSeconds: Int,
                    exportMode: ExportMode) {
            self.shareMode = shareMode
            self.forceLockSeconds = forceLockSeconds
            self.exportMode = exportMode
        }
    }
}
