//
// BreachAction.swift
// Proton Pass - Created on 10/04/2024.
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

public struct BreachAction: Decodable, Equatable, Sendable, Hashable {
    public let code, name, desc: String
    public let urls: [String]?

    public init(code: String, name: String, desc: String, urls: [String]?) {
        self.code = code
        self.name = name
        self.desc = desc
        self.urls = urls
    }

    public var knownCode: BreachActionCode {
        .init(code: code)
    }
}

public enum BreachActionCode: Sendable {
    case stayAlert
    case passwordExposed
    case passwordSource
    case passwordAll
    case twoFA
    case aliases
    case unknown

    init(code: String) {
        switch code.lowercased() {
        case "stay_alert":
            self = .stayAlert
        case "password_exposed":
            self = .passwordExposed
        case "password_source":
            self = .passwordSource
        case "passwords_all":
            self = .passwordAll
        case "2fa":
            self = .twoFA
        case "aliases":
            self = .aliases
        default:
            self = .unknown
        }
    }
}
