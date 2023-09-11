//
// Bundle+Extensions.swift
// Proton Pass - Created on 22/06/2023.
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

import Foundation

public extension Bundle {
    func parsePlist(ofName name: String) -> [String: AnyObject]? {
        // check if plist data available
        guard let plistURL = url(forResource: name, withExtension: "plist"),
              let data = try? Data(contentsOf: plistURL)
        else {
            assertionFailure("Could not find or parse the plist named \(name)")
            return nil
        }

        // parse plist into [String: AnyObject]
        guard let plistDictionary = try? PropertyListSerialization.propertyList(from: data,
                                                                                options: [],
                                                                                format: nil) as? [
            String: AnyObject
        ]
        else {
            assertionFailure("Could not serialise the content of the plist \(name) into a dictionary")
            return nil
        }

        return plistDictionary
    }

    func fetchPlistValue<T>(for key: String, in plist: String) -> T? {
        guard let plistDictionary = parsePlist(ofName: plist) else {
            return nil
        }

        return plistDictionary[key] as? T
    }

    func plistString(for key: ConstantPlistKey.Keys, in plist: ConstantPlistKey.PlistFiles) -> String {
        fetchPlistValue(for: key.rawValue, in: plist.rawValue) ?? ""
    }
}
