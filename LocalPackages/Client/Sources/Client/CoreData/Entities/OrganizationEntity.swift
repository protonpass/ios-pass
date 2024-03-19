//
// OrganizationEntity.swift
// Proton Pass - Created on 14/03/2024.
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

import CoreData
import Entities

@objc(OrganizationEntity)
public final class OrganizationEntity: NSManagedObject {}

extension OrganizationEntity: Identifiable {}

extension OrganizationEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<OrganizationEntity> {
        NSFetchRequest<OrganizationEntity>(entityName: "OrganizationEntity")
    }

    @NSManaged var userID: String
    @NSManaged var canUpdate: Bool
    @NSManaged var exportMode: Int64
    @NSManaged var forceLockSeconds: Int64
    @NSManaged var shareMode: Int64
}

extension OrganizationEntity {
    var toOrganization: Organization {
        let shareMode = Organization.ShareMode(rawValue: Int(shareMode)) ?? .default
        let exportMode = Organization.ExportMode(rawValue: Int(exportMode)) ?? .default
        let settings = Organization.Settings(shareMode: shareMode,
                                             forceLockSeconds: Int(forceLockSeconds),
                                             exportMode: exportMode)
        return .init(canUpdate: canUpdate, settings: settings)
    }

    func hydrate(from org: Organization, userId: String) {
        userID = userId
        canUpdate = org.canUpdate
        exportMode = Int64(org.settings.exportMode.rawValue)
        forceLockSeconds = Int64(org.settings.forceLockSeconds)
        shareMode = Int64(org.settings.shareMode.rawValue)
    }
}
