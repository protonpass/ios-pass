//
// FeedBackService.swift
// Proton Pass - Created on 28/06/2023.
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
import SupportSDK
import ZendeskCoreSDK

public final class FeedBackService: FeedBackServiceProtocol {
    private let service: Zendesk?
    private let requestProvider = ZDKRequestProvider()
    private let logger: Logger

    public init(logger: Logger) {
        service = Zendesk.instance
        self.logger = logger
        setUp()
    }

    func setUp() {
        Zendesk.initialize(appId: "2c3dd6c81637d247ab27f3b6c3808d9102c5be61046183be",
                           clientId: "mobile_sdk_client_daaf397ea48d678dc1a3",
                           zendeskUrl: "https://simplelogin.zendesk.com")
        Support.initialize(withZendesk: Zendesk.instance)
    }

    public func send(with title: String, and description: String, more information: Data?) {
        Task { [weak self] in
            do {
                let uploadResponse = try await ZDKUploadProvider().upload(file: information,
                                                                          with: "Log-\(Date()).log",
                                                                          and: information?
                                                                              .mimeType ??
                                                                              "application/octet-stream")
                let request = ZDKCreateRequest()
                if let uploadResponse {
                    request.attachments = [uploadResponse]
                }
                request.subject = title
                request.requestDescription = description
                request.tags = ["Feedback", "iOS"]
                let result = try await ZDKRequestProvider().createRequest(request: request)
                self?.logger.info("Zendesk result is: \(result ?? "Empty result")")
            } catch {
                self?.logger
                    .error("Something went wrong will sending feedback to Zendesk: \(error.localizedDescription)")
            }
        }
    }

    public func setUserIdentity(with identifier: String) {
        let identity = Identity.createAnonymous(name: "Test User", email: identifier)
        service?.setIdentity(identity)
    }
}

extension ZDKRequestProvider {
    func createRequest(request: ZDKCreateRequest) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            createRequest(request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
}

extension ZDKUploadProvider {
    func upload(file: Data?, with name: String, and type: String) async throws -> ZDKUploadResponse? {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(file,
                             withFilename: "image_name_app.png",
                             andContentType: "image/png") { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
}

extension Data {
    private static let mimeTypeSignatures: [UInt8: String] = [
        0xFF: "image/jpeg",
        0x89: "image/png",
        0x47: "image/gif",
        0x49: "image/tiff",
        0x4D: "image/tiff",
        0x25: "application/pdf",
        0xD0: "application/vnd",
        0x46: "text/plain"
    ]

    var mimeType: String {
        var copy: UInt8 = 0
        copyBytes(to: &copy, count: 1)
        return Data.mimeTypeSignatures[copy] ?? "application/octet-stream"
    }
}
