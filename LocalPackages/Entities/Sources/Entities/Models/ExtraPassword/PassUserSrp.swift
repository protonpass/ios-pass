//
// PassUserSrp.swift
// Proton Pass - Created on 05/06/2024.
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

import Foundation

public struct PassUserSrp: Sendable, Encodable {
    public let modulusId: String
    public let verifier: String
    public let salt: String

    enum CodingKeys: String, CodingKey {
        case modulusId = "SrpModulusID"
        case verifier = "SrpVerifier"
        case salt = "SrpSalt"
    }

    public init(modulusId: String, verifier: String, salt: String) {
        self.modulusId = modulusId
        self.verifier = verifier
        self.salt = salt
    }
}
