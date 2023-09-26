//
// Browser.swift
// Proton Pass - Created on 25/12/2022.
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

public enum Browser: Int, Codable, CustomStringConvertible {
    case safari = 0
    case inAppSafari = 1
    case chrome = 2
    case duckDuckGo = 3
    case firefox = 4
    case brave = 5
    case edge = 6
    case firefoxFocus = 7

    public static var thirdPartyBrowsers: [Browser] {
        [.chrome, .duckDuckGo, .firefox, .firefoxFocus, .brave, .edge]
    }

    public var description: String {
        switch self {
        case .safari:
            "Safari"
        case .inAppSafari:
            "In-App Safari"
        case .chrome:
            "Chrome"
        case .duckDuckGo:
            "DuckDuckGo"
        case .firefox:
            "Firefox"
        case .firefoxFocus:
            "Firefox Focus"
        case .brave:
            "Brave"
        case .edge:
            "Edge"
        }
    }

    public var appScheme: String? {
        switch self {
        case .chrome:
            "googlechrome://"
        case .duckDuckGo:
            "ddgQuickLink://"
        case .firefox:
            "firefox://open-url?url="
        case .firefoxFocus:
            "firefox-focus://open-url?url="
        case .brave:
            "brave://open-url?url="
        case .edge:
            "microsoft-edge://"
        default:
            nil
        }
    }
}
