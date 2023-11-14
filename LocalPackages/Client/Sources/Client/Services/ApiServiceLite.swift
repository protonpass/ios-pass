//
// ApiServiceLite.swift
// Proton Pass - Created on 09/11/2023.
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
//

import Entities
import Foundation
import ProtonCoreEnvironment

public protocol ApiServiceLiteProtocol {
    func execute(request: URLRequest) async throws -> NetworkCallResult
}

public final class ApiServiceLite: NSObject {
    lazy var session: URLSession = .init(configuration: .ephemeral,
                                         delegate: self,
                                         delegateQueue: .main)
}

extension ApiServiceLite: ApiServiceLiteProtocol {
    public func execute(request: URLRequest) async throws -> NetworkCallResult {
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PassError.network(.notHttpResponse)
        }
        return switch httpResponse.statusCode {
        case 401:
            .shouldRefreshAccessToken
        case 400, 402...499:
            .shouldLogOut
        default:
            .successful
        }
    }
}

extension ApiServiceLite: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?)
                               -> Void) {
        let validator = TrustKitWrapper.current?.pinningValidator
        if validator?.handle(challenge, completionHandler: completionHandler) == false {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
