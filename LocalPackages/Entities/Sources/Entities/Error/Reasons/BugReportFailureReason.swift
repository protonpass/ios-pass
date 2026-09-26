//
// BugReportFailureReason.swift
// Proton Pass - Created on 24/07/2026.
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

import Foundation

public extension PassError {
    enum BugReportFailureReason: CustomDebugStringConvertible, Sendable {
        case missingReason
        case shortDescription
        case longDescription(maxCharCount: Int)
        case tooManyFiles(maxFileCount: Int)
        case fileTooLarge(maxSizeInMb: Int)
        case failedToSend

        public var debugDescription: String {
            switch self {
            case .missingReason:
                "Missing report reason"

            case .shortDescription:
                "Report's description too short"

            case let .longDescription(maxCharCount):
                "Report's description is longer than \(maxCharCount) characters"

            case let .tooManyFiles(maxFileCount):
                "Report contains more than \(maxFileCount) files"

            case let .fileTooLarge(maxSizeInMb):
                "Attached file must be less than \(maxSizeInMb) MB"

            case .failedToSend:
                "Failed to send report"
            }
        }
    }
}
