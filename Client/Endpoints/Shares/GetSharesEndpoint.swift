//
// GetSharesEndpoint.swift
// Proton Pass - Created on 14/07/2022.
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

import ProtonCore_Services

public struct GetSharesEndpoint: Endpoint {
    public struct Response: Codable {
        let code: Int
        let shares: [PartialShare]
    }

    public var request: URLRequest

    public init(baseURL: URL,
                credential: ClientCredential) {
        let url = baseURL.appending(path: "/pass/v1/share")
        var request = URLRequest(url: url)
        request.method = .get
        request.addCredentialHeaders(credential)
        self.request = request
    }
}
