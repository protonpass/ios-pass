//
// TelemetryEventEntity.swift
// Proton Pass - Created on 24/04/2023.
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

import CoreData
import Entities

@objc(TelemetryEventEntity)
public final class TelemetryEventEntity: NSManagedObject {}

extension TelemetryEventEntity: Identifiable {}

extension TelemetryEventEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<TelemetryEventEntity> {
        NSFetchRequest<TelemetryEventEntity>(entityName: "TelemetryEventEntity")
    }

    @NSManaged var uuid: String
    @NSManaged var rawValue: String
    @NSManaged var time: Double
    @NSManaged var userID: String
}

extension TelemetryEventEntity {
    func toTelemetryEvent() throws -> TelemetryEvent {
        guard let type = TelemetryEventType(rawValue: rawValue) else {
            throw PassError.coreData(.corrupted(object: self, property: "rawValue"))
        }
        return .init(uuid: uuid, time: time, type: type)
    }

    func hydrate(from event: TelemetryEvent, userId: String) {
        uuid = event.uuid
        rawValue = event.type.rawValue
        time = event.time
        userID = userId
    }
}
