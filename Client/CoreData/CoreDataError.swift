//
// CoreDataError.swift
// Proton Pass - Created on 26/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public enum CoreDataError: Error, CustomDebugStringConvertible {
    case corrupted(object: NSManagedObject, property: String)
    case corruptedShareKeys(shareId: String)

    public var debugDescription: String {
        switch self {
        case let .corrupted(object, property):
            return "Corrupted \(type(of: object)): missing value for \(property)"
        case .corruptedShareKeys(let shareId):
            return "ItemKeys & VaultKeys are not synced for share with ID \(shareId)"
        }
    }
}
