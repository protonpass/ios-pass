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

import Foundation
import ProtonCore_Login

public struct BugReportRequest {
    public let os: String // iOS, MacOS
    public let osVersion: String
    public let client: String
    public let clientVersion: String
    public let clientType: Int // 1 = email, 2 = VPN, 5 = Pass
    public var title: String
    public var description: String
    public let username: String
    public var email: String
    public var country: String
    public var isp: String
    public var plan: String

    public init(with title: String, and description: String, userData: UserData) {
        #if os(iOS)
        os = "iOS"
        osVersion = UIDevice.current.systemVersion
        #elseif os(macOS)
        os = "MacOS"
        osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        #endif
        client = "App"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        clientVersion = "\(appVersion) (\(appBuild))"
        clientType = 5
        self.title = title
        self.description = description
        username = userData.user.name ?? ""
        email = userData.user.email ?? ""
        country = ""
        isp = ""
        plan = ""
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
        case country = "Country"
        case isp = "ISP"
        case plan = "Plan"
    }
}
