//
// ParseTotpUri.swift
// Proton Pass - Created on 15/09/2023.
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

import Entities

import PassRustCore

public protocol ParseTotpUriUseCase: Sendable {
    func execute(_ uri: String) throws -> Entities.TotpComponents
}

public extension ParseTotpUriUseCase {
    func callAsFunction(_ uri: String) throws -> Entities.TotpComponents {
        try execute(uri)
    }
}

public final class ParseTotpUri: ParseTotpUriUseCase {
    public init() {}

    public func execute(_ uri: String) throws -> Entities.TotpComponents {
        try TotpUriParser().parse(uriString: uri).toDomainComponents()
    }
}

private extension PassRustCore.TotpAlgorithm {
    func toDomainAlgorithm() -> Entities.TotpAlgorithm {
        switch self {
        case .sha1:
            .sha1
        case .sha256:
            .sha256
        case .sha512:
            .sha512
        }
    }
}

private extension PassRustCore.Totp {
    func toDomainComponents() -> Entities.TotpComponents {
        .init(secret: secret,
              label: label,
              issuer: issuer,
              algorithm: (algorithm ?? .sha1).toDomainAlgorithm(),
              digits: Int(digits ?? 6),
              period: Int(period ?? 30))
    }
}
