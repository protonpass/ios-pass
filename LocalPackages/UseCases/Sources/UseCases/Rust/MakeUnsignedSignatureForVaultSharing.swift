//
// MakeUnsignedSignatureForVaultSharing.swift
// Proton Pass - Created on 13/10/2023.
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

import Foundation
import PassRustCore

public protocol MakeUnsignedSignatureForVaultSharingUseCase: Sendable {
    func execute(email: String, vaultKey: Data) -> Data
}

public extension MakeUnsignedSignatureForVaultSharingUseCase {
    func callAsFunction(email: String, vaultKey: Data) -> Data {
        execute(email: email, vaultKey: vaultKey)
    }
}

public final class MakeUnsignedSignatureForVaultSharing: MakeUnsignedSignatureForVaultSharingUseCase {
    public init() {}

    public func execute(email: String, vaultKey: Data) -> Data {
        NewUserInviteCreator().createSignatureBody(email: email, vaultKey: vaultKey)
    }
}
