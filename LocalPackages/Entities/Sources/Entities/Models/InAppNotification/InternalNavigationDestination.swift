//
// InternalNavigationDestination.swift
// Proton Pass - Created on 19/11/2024.
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

import Foundation

// swiflint:disable cyclomatic_complexity
public enum InternalNavigationDestination: Equatable, Sendable {
    case viewVaultMembers(shareID: String)
    case aliasBreach(shareID: String, itemID: String)
    case customEmailBreach(customEmailID: String)
    case addressBreach(addressID: String)
    case upgrade
    case viewItem(shareID: String, itemID: String)

    /// Parse the URL and return the corresponding enum case with parameters
    public static func parse(urlString: String) -> InternalNavigationDestination? {
        guard let url = URLComponents(string: urlString) else { return nil }

        // Extract the path
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = path.split(separator: "/")

        guard components.count == 2, components.first == "internal" else { return nil }

        let destinationString = String(components[1])
        let queryParams = url.queryItems?.reduce(into: [String: String]()) { result, item in
            if let value = item.value {
                result[item.name] = value
            }
        } ?? [:]

        // Match the destination and populate associated values
        switch destinationString {
        case "share_members":
            if let shareID = queryParams["ShareID"] {
                return .viewVaultMembers(shareID: shareID)
            }
        case "alias_breach":
            if let shareID = queryParams["ShareID"], let itemID = queryParams["ItemID"] {
                return .aliasBreach(shareID: shareID, itemID: itemID)
            }
        case "custom_email_breach":
            if let customEmailID = queryParams["CustomEmailID"] {
                return .customEmailBreach(customEmailID: customEmailID)
            }
        case "address_breach":
            if let addressID = queryParams["AddressID"] {
                return .addressBreach(addressID: addressID)
            }
        case "upgrade":
            return .upgrade
        case "view_item":
            if let shareID = queryParams["ShareID"], let itemID = queryParams["ItemID"] {
                return .viewItem(shareID: shareID, itemID: itemID)
            }
        default:
            return nil
        }

        return nil
    }
}

// swiflint:enable cyclomatic_complexity
