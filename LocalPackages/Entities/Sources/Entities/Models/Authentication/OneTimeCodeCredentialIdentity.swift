//
// OneTimeCodeCredentialIdentity.swift
// Proton Pass - Created on 17/09/2024.
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

@preconcurrency import AuthenticationServices

/// Wrap `ASOneTimeCodeCredentialIdentity` as it's iOS 18 only
/// Can be removed once iOS 17 is dropped
public struct OneTimeCodeCredentialIdentity: Sendable {
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let recordIdentifier: String?

    public init(serviceIdentifier: ASCredentialServiceIdentifier,
                recordIdentifier: String?) {
        self.serviceIdentifier = serviceIdentifier
        self.recordIdentifier = recordIdentifier
    }
}
