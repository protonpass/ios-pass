//
// TempDirectoryTransferableUrl.swift
// Proton Pass - Created on 29/11/2024.
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

import CoreTransferable
import Foundation

public struct TempDirectoryTransferableUrl: Sendable, Transferable {
    public let value: URL

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .data,
                           exporting: { data in
                               SentTransferredFile(data.value)
                           },
                           importing: { received in
                               let url = try received.file.copyFileToTempDirectory()
                               return Self(value: url)
                           })
    }
}
