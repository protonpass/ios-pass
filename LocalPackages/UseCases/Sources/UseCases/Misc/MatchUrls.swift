//
// MatchUrls.swift
// Proton Pass - Created on 02/05/2024.
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
//

import Entities
import Foundation

public protocol MatchUrlsUseCase: Sendable {
    func execute(_ leftUrl: URL, with rightUrl: URL) throws -> UrlMatchResult
}

public extension MatchUrlsUseCase {
    func callAsFunction(_ leftUrl: URL,
                        with rightUrl: URL) throws -> UrlMatchResult {
        try execute(leftUrl, with: rightUrl)
    }
}

public final class MatchUrls: MatchUrlsUseCase {
    private let getRootDomain: any GetRootDomainUseCase

    public init(getRootDomain: any GetRootDomainUseCase) {
        self.getRootDomain = getRootDomain
    }

    public func execute(_ leftUrl: URL, with rightUrl: URL) throws -> UrlMatchResult {
        guard let leftScheme = leftUrl.scheme,
              let rightScheme = rightUrl.scheme,
              let leftHost = leftUrl.host,
              let rightHost = rightUrl.host else { return .notMatched }

        let httpHttps = ["http", "https"]
        if httpHttps.contains(leftScheme), httpHttps.contains(rightScheme) {
            if leftScheme == "https", rightScheme == "http" {
                return .notMatched
            } else {
                guard let leftRootDomain = try? getRootDomain(of: leftUrl),
                      let rightRootDomain = try? getRootDomain(of: rightUrl),
                      leftRootDomain == rightRootDomain else {
                    return .notMatched
                }

                var leftSubdomains = leftHost.components(separatedBy: ".")
                var rightSubdomains = rightHost.components(separatedBy: ".")

                var matchScore = 1_000
                while let lastLeftSubdomain = leftSubdomains.popLast() {
                    let lastRightSubdomain = rightSubdomains.popLast()
                    if lastLeftSubdomain != lastRightSubdomain {
                        matchScore -= 1
                    }
                }
                matchScore -= rightSubdomains.count

                return .matched(matchScore)
            }
        } else {
            // Other schemes like `ssh` or `ftp`...
            if leftScheme == rightScheme, leftHost == rightHost {
                return .matched(1_000)
            } else {
                return .notMatched
            }
        }
    }
}
