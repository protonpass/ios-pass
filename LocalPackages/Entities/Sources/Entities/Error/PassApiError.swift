//
// PassApiError.swift
// Proton Pass - Created on 05/03/2024.
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

public enum PassApiError: Int, Error {
    /// The resource you are trying to update has a newer key. Refetch the vault keys.
    case notLatestKey = 300_001

    /// You are trying to update an item that has a newer revision stored in the backend. You should get the latest
    /// revision.
    case notLatestRevision = 300_002

    /// You aren't using the latest address key for the user you want to encrypt this for.
    case invalidSignature = 300_003

    /// This share has been disabled. It means you no longer have access to it so you should delete it from your
    /// list of known shares.
    case disabledShare = 300_004

    case rotationPayloadIncomplete = 300_005

    case missingKeys = 300_006

    /// The user has created too many of this resource. You can't create more of this.
    case resourceLimitExceeded = 300_007

    /// This session is locked. You need to call the unlock route before.
    case sessionLocked = 300_008

    /// Invalid validation (e.g custom email validation)
    case invalidValidation = 2_001

    /// Not allowed (e.g custom email is removed or wrong extra password)
    case notAllowed = 2_011

    /// To many wrong attempts (e.g wrong extra password many times)
    case tooManyWrongAttempts = 2_026

    case itemDoesNotExist = 2_501
}
