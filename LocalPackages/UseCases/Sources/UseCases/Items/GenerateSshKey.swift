//
// GenerateSshKey.swift
// Proton Pass - Created on 15/01/2026.
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

import Entities
import PassRustCore

public protocol GenerateSshKeyUseCase: Sendable {
    func execute(comment: String,
                 type: Entities.SshKeyType,
                 passphrase: String?) throws -> SshKeyComponents
}

public extension GenerateSshKeyUseCase {
    func callAsFunction(comment: String,
                        type: Entities.SshKeyType,
                        passphrase: String?) throws -> SshKeyComponents {
        try execute(comment: comment, type: type, passphrase: passphrase)
    }
}

public final class GenerateSshKey: GenerateSshKeyUseCase {
    public let manager: any SshKeyManagerProtocol

    public init(manager: any SshKeyManagerProtocol = SshKeyManager()) {
        self.manager = manager
    }

    public func execute(comment: String,
                        type: Entities.SshKeyType,
                        passphrase: String?) throws -> SshKeyComponents {
        let key = try manager.generateSshKey(comment: comment,
                                             keyType: type.rustType,
                                             passphrase: passphrase)
        return .init(private: key.privateKey, public: key.publicKey)
    }
}

private extension Entities.SshKeyType {
    var rustType: PassRustCore.SshKeyType {
        switch self {
        case .rsa2048: .rsa2048
        case .rsa4096: .rsa4096
        case .ed25519: .ed25519
        }
    }
}
