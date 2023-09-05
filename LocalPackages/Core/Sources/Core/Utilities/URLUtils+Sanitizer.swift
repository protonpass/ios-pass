//
// URLUtils+Sanitizer.swift
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
    enum Sanitizer {
        /// Sanitize user's input URL string into a valid one.
        /// If `urlString` is a valid URI. Return the `urlString` as it is
        /// If `urlString` string does not have scheme (protocol) (e.g `http`, `https` or `ftp`),
        /// automatically add `https` as scheme
        /// - Parameters:
        ///   - urlString: user's input URL string
        /// - Returns:
        /// A sanitized URL string if any.
        /// `nil` if `urlString` is not valid
        public static func sanitize(_ urlString: String) -> String? {
            let httpsUrlString = "https://" + urlString
            if let httpsUrl = URL(string: httpsUrlString),
               httpsUrl.scheme != nil,
               let httpsUrlHost = httpsUrl.host,
               httpsUrlHost.components(separatedBy: ".").count > 1 {
                return httpsUrlString
            }

            if let url = URL(string: urlString),
               url.scheme != nil,
               let host = url.host,
               host.components(separatedBy: ".").count > 1 {
                return urlString
            }

            return nil
        }

        public static func sanitizeAndGetRootDomain(_ urlString: String,
                                                    domainParser: DomainParser) -> String {
            guard let sanitizedUrlString = sanitize(urlString),
                  let host = URL(string: sanitizedUrlString)?.host,
                  let parsedHost = domainParser.parse(host: host) else { return urlString }
            let publicSufix = parsedHost.publicSuffix
            let domains = host.components(separatedBy: ".")
            var rootDomain = ""
            var foundPublixSuffix = false
            for domain in domains.reversed() {
                if rootDomain.isEmpty {
                    rootDomain = domain
                } else {
                    rootDomain = "\(domain).\(rootDomain)"
                }

                if foundPublixSuffix {
                    return rootDomain
                }

                foundPublixSuffix = rootDomain == publicSufix
            }
            return rootDomain
        }
    }
}
