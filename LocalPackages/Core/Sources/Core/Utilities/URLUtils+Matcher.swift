//
// URLUtils+Matcher.swift
// Proton Pass - Created on 10/10/2022.
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

import Foundation

public extension URLUtils {
    /// Compare 2 URLs given a set of allowed schemes (protocols)
    enum Matcher {
        /// `matched` case associates an `Int` as match score
        public enum MatchResult {
            case matched(Int)
            case notMatched

            public var score: Int {
                if case let .matched(score) = self {
                    return score
                }
                return 0
            }
        }

        /// Compare if 2 URLs are matched and if they are matched, also indicate match score.
        /// match score starts from `1000` and decreases gradually.
        /// - Parameters:
        ///    - leftUrl: Left hand `URL`
        ///    - rightUrl: Right hand `URL`
        ///    - domainParser: `DomainParser` object that makes use of TLD list to compare URLs.
        /// Is `nil` by default and should be injected if heavily used in order to avoid expensive initialization.
        public static func compare(_ leftUrl: URL,
                                   _ rightUrl: URL,
                                   domainParser: DomainParser? = nil) -> MatchResult {
            guard let leftScheme = leftUrl.scheme,
                  let rightScheme = rightUrl.scheme,
                  let leftHost = leftUrl.host,
                  let rightHost = rightUrl.host else { return .notMatched }

            let httpHttps = ["http", "https"]
            if httpHttps.contains(leftScheme), httpHttps.contains(rightScheme) {
                if leftScheme == "https", rightScheme == "http" {
                    return .notMatched
                } else {
                    guard let domainParser = domainParser ?? (try? DomainParser()),
                          let parsedLeftHost = domainParser.parse(host: leftHost),
                          let parsedRightHost = domainParser.parse(host: rightHost),
                          parsedLeftHost.publicSuffix == parsedRightHost.publicSuffix else {
                        return .notMatched
                    }

                    guard let leftDomain = parsedLeftHost.domain,
                          let rightDomain = parsedRightHost.domain,
                          leftDomain == rightDomain else {
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
}

extension URLUtils.Matcher.MatchResult: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.matched(lScore), .matched(rScore)):
            lScore == rScore
        case (.notMatched, .notMatched):
            true
        default:
            false
        }
    }
}
