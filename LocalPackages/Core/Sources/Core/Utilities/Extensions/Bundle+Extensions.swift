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

public extension Bundle {
    var versionNumber: String {
        string(forKey: "CFBundleShortVersionString") ?? "0.0.0"
    }

    var buildNumber: String {
        string(forKey: "CFBundleVersion") ?? "0"
    }

    var versionIdentifier: String? {
        string(forKey: "APP_VERSION_IDENTIFIER")
    }

    var gitCommitHash: String? {
        string(forKey: "GIT_COMMIT_HASH")
    }

    var isQaBuild: Bool {
        bool(forKey: "IS_QA_BUILD")
    }

    var isBetaBuild: Bool {
        bool(forKey: "IS_BETA_BUILD")
    }

    /// Get the full name of the current version e.g "1.0.0-dev" or "1.2.0"
    var fullAppVersionName: String {
        if let versionIdentifier, !versionIdentifier.isEmpty {
            return "\(versionNumber)-\(versionIdentifier)"
        }
        return versionNumber
    }

    /// Full app version name + build number + git commit hash
    /// E.g: 1.0.0 (1) (abcdef)
    var displayedAppVersion: String {
        let fullAppVersionName = Bundle.main.fullAppVersionName
        let buildNumber = Bundle.main.buildNumber
        if let gitCommitHash = Bundle.main.gitCommitHash {
            return "\(fullAppVersionName) (\(buildNumber)) (\(gitCommitHash))"
        } else {
            assertionFailure("Missing git commit hash")
            return "\(fullAppVersionName) (\(buildNumber))"
        }
    }
}

private extension Bundle {
    func string(forKey key: String) -> String? {
        infoDictionary?[key] as? String
    }

    /// Default to `false` if the key does not exist
    func bool(forKey key: String) -> Bool {
        let boolString = infoDictionary?[key] as? String
        return boolString == "YES"
    }
}
