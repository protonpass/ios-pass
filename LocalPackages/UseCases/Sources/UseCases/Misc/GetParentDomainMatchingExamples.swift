//
// GetParentDomainMatchingExamples.swift
// Proton Pass - Created on 08/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import Entities
import Foundation

public protocol GetParentDomainMatchingExamplesUseCase: Sendable {
    func callAsFunction(for urlString: String) -> [DomainMatchingExample]
}

public struct GetParentDomainMatchingExamples: GetParentDomainMatchingExamplesUseCase {
    private let getRootDomain: any GetRootDomainUseCase

    public init(getRootDomain: any GetRootDomainUseCase) {
        self.getRootDomain = getRootDomain
    }

    public func callAsFunction(for urlString: String) -> [DomainMatchingExample] {
        guard let url = URLUtils.Sanitizer.sanitize(urlString).flatMap(URL.init(string:)),
              let scheme = url.scheme,
              case let (name, suffix)? = (try? getRootDomain(of: url))?.splitAtFirstDot else {
            return []
        }
        let root = "\(name).\(suffix)"
        let otherSuffix = suffix == "net" ? "com" : "net"
        let unrelatedDomain = root == "google.com" ? "proton.me" : "google.com"
        return [
            .init(url: "\(scheme)://\(root)", suggested: true),
            .init(url: "\(scheme)://subdomain.\(root)", suggested: true),
            .init(url: "\(scheme)://\(name).\(otherSuffix)", suggested: false),
            .init(url: "\(scheme)://\(unrelatedDomain)", suggested: false)
        ]
    }
}

private extension String {
    var splitAtFirstDot: (String, String)? {
        guard let dotIndex = firstIndex(of: "."),
              dotIndex != startIndex,
              dotIndex != index(before: endIndex) else {
            return nil
        }
        return (String(self[..<dotIndex]), String(self[index(after: dotIndex)...]))
    }
}
