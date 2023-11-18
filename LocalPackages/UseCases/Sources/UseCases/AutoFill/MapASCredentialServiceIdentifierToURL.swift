//
// MapASCredentialServiceIdentifierToURL.swift
// Proton Pass - Created on 10/11/2023.
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

#if canImport(AuthenticationServices)
import AuthenticationServices

public protocol MapASCredentialServiceIdentifierToURLUseCase: Sendable {
    func execute(identifier: ASCredentialServiceIdentifier) -> URL?
}

public extension MapASCredentialServiceIdentifierToURLUseCase {
    func callAsFunction(identifier: ASCredentialServiceIdentifier) -> URL? {
        execute(identifier: identifier)
    }
}

public final class MapASCredentialServiceIdentifierToURL: MapASCredentialServiceIdentifierToURLUseCase {
    public init() {}

    public func execute(identifier: ASCredentialServiceIdentifier) -> URL? {
        // ".domain" means in app context where identifiers don't have protocol,
        // so we manually add https as protocol otherwise URL comparison would not work without protocol.
        let urlString = switch identifier.type {
        case .domain:
            "https://\(identifier.identifier)"
        case .URL:
            identifier.identifier
        @unknown default:
            identifier.identifier
        }
        return URL(string: urlString)
    }
}

#endif
