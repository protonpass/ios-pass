//
// CreatePasskey.swift
// Proton Pass - Created on 20/02/2024.
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

import Entities
import Foundation
import PassRustCore

public typealias CreatePasskeyResponse = CreatePasskeyIosResponse

public protocol CreatePasskeyUseCase: Sendable {
    func execute(_ request: PasskeyCredentialRequest) throws -> CreatePasskeyResponse
}

public extension CreatePasskeyUseCase {
    func callAsFunction(_ request: PasskeyCredentialRequest) throws -> CreatePasskeyResponse {
        try execute(request)
    }
}

public final class CreatePasskey: CreatePasskeyUseCase {
    public init() {}

    public func execute(_ request: PasskeyCredentialRequest) throws -> CreatePasskeyResponse {
        let supportedAlgorithms = request.supportedAlgorithms.map { Int64($0.rawValue) }
        let createRequest = CreatePasskeyIosRequest(serviceIdentifier: request.serviceIdentifier.identifier,
                                                    rpId: request.relyingPartyIdentifier,
                                                    userName: request.userName,
                                                    userHandle: request.userHandle,
                                                    clientDataHash: request.clientDataHash,
                                                    supportedAlgorithms: supportedAlgorithms)
        return try PasskeyManager().generateIosPasskey(request: createRequest)
    }
}
