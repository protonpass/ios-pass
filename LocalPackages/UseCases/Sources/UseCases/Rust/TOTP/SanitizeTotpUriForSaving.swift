//
// SanitizeTotpUriForSaving.swift
// Proton Pass - Created on 30/09/2023.
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

import PassRustCore

public protocol SanitizeTotpUriForSavingUseCase: Sendable {
    /// Throw an error of type `TotpError`
    func execute(originalUri: String, editedUri: String) throws -> String
}

public extension SanitizeTotpUriForSavingUseCase {
    func callAsFunction(originalUri: String, editedUri: String) throws -> String {
        try execute(originalUri: originalUri, editedUri: editedUri)
    }
}

public final class SanitizeTotpUriForSaving: SanitizeTotpUriForSavingUseCase {
    public init() {}

    public func execute(originalUri: String, editedUri: String) throws -> String {
        try TotpUriSanitizer().uriForSaving(originalUri: originalUri, editedUri: editedUri)
    }
}
