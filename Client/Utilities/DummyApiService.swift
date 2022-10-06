//
// DummyApiService.swift
// Proton Pass - Created on 16/07/2022.
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

import Core
import ProtonCore_Doh
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services

/// For preview purposes
public struct DummyApiService: APIService {
    public var sessionUID = ""
    public var serviceDelegate: APIServiceDelegate?
    public var authDelegate: AuthDelegate?
    public var humanDelegate: HumanVerifyDelegate?
    public var doh: DoH & ServerConfig = PPDoH(bundle: .main)
    public var signUpDomain = ""

    public func setSessionUID(uid: String) { }

    // swiftlint:disable function_parameter_count
    public func request(method: HTTPMethod,
                        path: String,
                        parameters: Any?,
                        headers: [String: Any]?,
                        authenticated: Bool,
                        autoRetry: Bool,
                        customAuthCredential: AuthCredential?,
                        nonDefaultTimeout: TimeInterval?,
                        retryPolicy: ProtonRetryPolicy.RetryMode,
                        jsonCompletion: @escaping JSONCompletion) {}

    public func request<T>(method: HTTPMethod,
                           path: String,
                           parameters: Any?,
                           headers: [String: Any]?,
                           authenticated: Bool,
                           autoRetry: Bool,
                           customAuthCredential: AuthCredential?,
                           nonDefaultTimeout: TimeInterval?,
                           retryPolicy: ProtonRetryPolicy.RetryMode,
                           decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {}

    public func download(byUrl url: String,
                         destinationDirectoryURL: URL,
                         headers: [String: Any]?,
                         authenticated: Bool,
                         customAuthCredential: AuthCredential?,
                         nonDefaultTimeout: TimeInterval?,
                         retryPolicy: ProtonRetryPolicy.RetryMode,
                         downloadTask: ((URLSessionDownloadTask) -> Void)?,
                         downloadCompletion: @escaping DownloadCompletion) {}

    public func upload(byPath path: String,
                       parameters: [String: String],
                       keyPackets: Data,
                       dataPacket: Data,
                       signature: Data?,
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       retryPolicy: ProtonRetryPolicy.RetryMode,
                       uploadProgress: ProgressCompletion?,
                       jsonCompletion: @escaping JSONCompletion) {}

    public func upload<T>(byPath path: String,
                          parameters: [String: String],
                          keyPackets: Data,
                          dataPacket: Data,
                          signature: Data?,
                          headers: [String: Any]?,
                          authenticated: Bool,
                          customAuthCredential: AuthCredential?,
                          nonDefaultTimeout: TimeInterval?,
                          retryPolicy: ProtonRetryPolicy.RetryMode,
                          uploadProgress: ProgressCompletion?,
                          decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {}

    public func upload(byPath path: String,
                       parameters: Any?,
                       files: [String: URL],
                       headers: [String: Any]?,
                       authenticated: Bool,
                       customAuthCredential: AuthCredential?,
                       nonDefaultTimeout: TimeInterval?,
                       retryPolicy: ProtonRetryPolicy.RetryMode,
                       uploadProgress: ProgressCompletion?,
                       jsonCompletion: @escaping JSONCompletion) {}

    public func upload<T>(byPath path: String,
                          parameters: Any?,
                          files: [String: URL],
                          headers: [String: Any]?,
                          authenticated: Bool,
                          customAuthCredential: AuthCredential?,
                          nonDefaultTimeout: TimeInterval?,
                          retryPolicy: ProtonRetryPolicy.RetryMode,
                          uploadProgress: ProgressCompletion?,
                          decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {}

    public func uploadFromFile(byPath path: String,
                               parameters: [String: String],
                               keyPackets: Data,
                               dataPacketSourceFileURL: URL,
                               signature: Data?,
                               headers: [String: Any]?,
                               authenticated: Bool,
                               customAuthCredential: AuthCredential?,
                               nonDefaultTimeout: TimeInterval?,
                               retryPolicy: ProtonRetryPolicy.RetryMode,
                               uploadProgress: ProgressCompletion?,
                               jsonCompletion: @escaping JSONCompletion) {}

    public func uploadFromFile<T>(
        byPath path: String,
        parameters: [String: String],
        keyPackets: Data,
        dataPacketSourceFileURL: URL,
        signature: Data?,
        headers: [String: Any]?,
        authenticated: Bool,
        customAuthCredential: AuthCredential?,
        nonDefaultTimeout: TimeInterval?,
        retryPolicy: ProtonRetryPolicy.RetryMode,
        uploadProgress: ProgressCompletion?,
        decodableCompletion: @escaping DecodableCompletion<T>) where T: APIDecodableResponse {}
    // swiftlint:enable function_parameter_count

    public static var preview: DummyApiService { .init() }
}
