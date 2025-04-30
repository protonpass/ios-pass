//
// SanitizeFileName.swift
// Proton Pass - Created on 30/04/2025.
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
//

import PassRustCore

public protocol SanitizeFileNameUseCase: Sendable {
    func execute(_ fileName: String) -> String
}

public extension SanitizeFileNameUseCase {
    func callAsFunction(_ fileName: String) -> String {
        execute(fileName)
    }
}

public final class SanitizeFileName: SanitizeFileNameUseCase {
    private let fileDecoder: any FileDecoderProtocol

    public init(fileDecoder: any FileDecoderProtocol = FileDecoder()) {
        self.fileDecoder = fileDecoder
    }

    public func execute(_ fileName: String) -> String {
        // When initializing FileHandle using FileHandle(forWritingTo:), file name with some characters
        // fails the initialization hence break the whole download process.
        // So we replace characters by hyphens to bypass this system bug.
        var fileName = fileName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
            .replacingOccurrences(of: "%", with: "-")
            .replacingOccurrences(of: "*", with: "-")
            .replacingOccurrences(of: "?", with: "-")
            .replacingOccurrences(of: "#", with: "-")
            .replacingOccurrences(of: "<", with: "-")
            .replacingOccurrences(of: ">", with: "-")
            .replacingOccurrences(of: "|", with: "-")
            .replacingOccurrences(of: "\"", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        fileName = fileDecoder.sanitizeFilename(name: fileName, windows: false)

        // Remove accents
        return fileName.folding(options: .diacriticInsensitive,
                                locale: .init(identifier: "en_US"))
    }
}
