//
// URLExtensions.swift
// Proton Pass - Created on 06/12/2022.
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

import Foundation

public extension URL {
    /// String that contains only `scheme` & `host` of an `URL`
    /// E.g:`https://www.example.com/path/to/sth` -> `https://www.example.com`
    var schemeAndHost: String {
        guard let scheme, let host = host() else { return "" }
        return "\(scheme)://\(host)"
    }

    // periphery:ignore
    /// Get value of a query parameter.
    /// E.g: Given an URL `https://example.com?param1=123&param2=abc`
    /// `url["param1"]` returns `123`
    /// `url["param2"]` returns `abc`
    /// `url["param3"]` returns `nil`
    subscript(parameter: String) -> String? {
        guard let components = URLComponents(string: absoluteString) else { return nil }
        return components.queryItems?.first(where: { $0.name == parameter })?.value
    }

    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer =
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }

    func copyFileToTempDirectory() throws -> URL {
        let copy = URL.temporaryDirectory.appending(path: lastPathComponent)

        if FileManager.default.fileExists(atPath: copy.relativePath) {
            try FileManager.default.removeItem(at: copy)
        }

        try FileManager.default.copyItem(at: self, to: copy)
        return copy
    }
}
