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
    // Generating RSA keys takes seconds so we offload the generation from main thread
    @concurrent
    func execute(type: Entities.SshKeyType) async throws -> SshKeyComponents
}

public extension GenerateSshKeyUseCase {
    @concurrent
    func callAsFunction(type: Entities.SshKeyType) async throws -> SshKeyComponents {
        try await execute(type: type)
    }
}

public final class GenerateSshKey: GenerateSshKeyUseCase {
    public let manager: any SshKeyManagerProtocol

    public init(manager: any SshKeyManagerProtocol = SshKeyManager()) {
        self.manager = manager
    }

    @concurrent
    public func execute(type: Entities.SshKeyType) async throws -> SshKeyComponents {
        let key = try manager.generateSshKey(comment: "",
                                             keyType: type.rustType,
                                             passphrase: nil)
        return .init(privateKey: key.privateKey, publicKey: key.publicKey)
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
