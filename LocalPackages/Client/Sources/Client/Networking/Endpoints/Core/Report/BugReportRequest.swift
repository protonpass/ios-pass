//
// BugReportRequest.swift
// Proton Pass - Created on 03/07/2023.
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

import Core
import Foundation
import ProtonCoreLogin
import UIKit

public struct BugReportRequest: Sendable {
    public let os: String // iOS, MacOS
    public let osVersion: String
    public let client: String
    public let clientVersion: String
    public let clientType: String // 1 = email, 2 = VPN, 5 = Pass
    public var title: String
    public var description: String
    public let username: String
    public let email: String

    public init(with title: String, and description: String, userData: UserData) async {
        #if os(iOS)
        os = "iOS"
        osVersion = await UIDevice.current.systemVersion
        #elseif os(macOS)
        os = "MacOS"
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif
        client = "App"
        clientVersion = Bundle.main.fullAppVersionName
        clientType = "\(5)"
        self.title = title
        self.description = description
        username = userData.user.name ?? ""
        email = userData.user.email ?? ""
    }
}

extension BugReportRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case os = "OS"
        case osVersion = "OSVersion"
        case client = "Client"
        case clientVersion = "ClientVersion"
        case clientType = "ClientType"
        case title = "Title"
        case description = "Description"
        case username = "Username"
        case email = "Email"
    }
}
