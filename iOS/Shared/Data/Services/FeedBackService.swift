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
import ZendeskMessagingSDKTargets

public final class FeedBackService: @unchecked Sendable, FeedBackServiceProtocol {
    private let service: Zendesk?
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

    public func send(with title: String,
                     and description: String,
                     more information: Data?,
                     tag: String) async -> Bool {
        do {
            let uploadResponse = try await ZDKUploadProvider().upload(file: information,
                                                                      with: "Log-\(Date()).txt",
                                                                      and: information?.mimeType ??
                                                                          "application/octet-stream")
            let request = ZDKCreateRequest()
            if let uploadResponse {
                request.attachments.append(uploadResponse)
            }
            request.subject = title
            request.requestDescription = description
            request.tags = ["Feedback", "iOS", tag]
            let result = try await ZDKRequestProvider().createRequest(request: request)
            logger.info("Zendesk result is: \(result ?? "Empty result")")
            return true
        } catch {
            logger
                .error("Something went wrong will sending feedback to Zendesk: \(error.localizedDescription)")
            return true
        }
    }

    public func setUserIdentity(with identifier: String) {
        let identity = Identity.createAnonymous(name: "Test User", email: identifier)
        service?.setIdentity(identity)
    }
}

// MARK: Utils extensions

private extension ZDKRequestProvider {
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

private extension ZDKUploadProvider {
    func upload(file: Data?, with name: String, and type: String) async throws -> ZDKUploadResponse? {
        try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(file,
                             withFilename: name,
                             andContentType: type) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
}
