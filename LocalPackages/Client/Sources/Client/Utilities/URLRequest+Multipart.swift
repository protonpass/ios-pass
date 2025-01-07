//
// URLRequest+Multipart.swift
// Proton Pass - Created on 11/12/2024.
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
import ProtonCoreNetworking

public struct MultipartInfo: Sendable {
    let name: String
    var fileName: String?
    var contentType: String?
    let data: Data
}

extension URLRequest {
    init(url: URL,
         path: String,
         credential: Credential,
         infos: [MultipartInfo],
         appVersion: String) {
        // Construct the body
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n")
        for info in infos {
            let disposition = if let fileName = info.fileName {
                "name=\"\(info.name)\"; filename=\"\(fileName)\""
            } else {
                "name=\"\(info.name)\""
            }
            body.append("Content-Disposition: \(disposition)\r\n")

            if let contentType = info.contentType {
                body.append("Content-Type: \(contentType)\r\n")
            }
            body.append("Content-Length: \(info.data.count)\r\n\r\n")
            body.append(info.data)
            body.append("\r\n--\(boundary)\r\n")
        }

        // Construct the headers
        var headers = [String: String](credential: credential, appVersion: appVersion)
        headers["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        headers["Content-Length"] = "\(body.count)"

        // Construct the final request
        var request = URLRequest(url: url.appending(path: path))
        request.httpMethod = "POST"
        request.httpBody = body
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        self = request
    }

    init(url: URL,
         path: String,
         credential: Credential,
         appVersion: String) {
        // Construct the headers
        let headers = [String: String](credential: credential, appVersion: appVersion)

        // Construct the final request
        var request = URLRequest(url: url.appending(path: path))
        request.httpMethod = "GET"
        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        self = request
    }
}

private extension [String: String] {
    // Construct base headers with common required ones
    // periphery:ignore
    init(credential: Credential, appVersion: String) {
        var headers = [String: String]()
        headers["Accept"] = "application/vnd.protonmail.v1+json"
        headers["x-pm-appversion"] = appVersion
        headers["Authorization"] = "Bearer \(credential.accessToken)"
        headers["x-pm-uid"] = credential.UID
        self = headers
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
