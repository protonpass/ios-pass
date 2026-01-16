//
// SshKey.swift
// Proton Pass - Created on 11/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public enum SshKeyType: Sendable, CaseIterable {
    case ed25519, rsa2048, rsa4096

    public static var `default`: Self { .ed25519 }

    public var title: String {
        switch self {
        case .ed25519:
            "Ed25519"
        case .rsa2048:
            "RSA-2048"
        case .rsa4096:
            "RSA-2048"
        }
    }
}

public enum SshKeyComponent: Int, Sendable, Identifiable {
    case `public`, `private`

    public var id: Int {
        rawValue
    }
}

public struct SshKeyComponents: Sendable {
    public let `private`: String
    public let `public`: String

    public init(private: String, public: String) {
        self.private = `private`
        self.public = `public`
    }
}

public struct SshKeyOptions {
    public let type: SshKeyType
    public let comment: String
    public let passphrase: String

    public init(type: SshKeyType, comment: String, passphrase: String) {
        self.type = type
        self.comment = comment
        self.passphrase = passphrase
    }
}
