//
// GetFileGroup.swift
// Proton Pass - Created on 27/11/2024.
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
@preconcurrency import PassRustCore

public protocol GetFileGroupUseCase: Sendable {
    func execute(mimeType: String) -> Entities.FileGroup
}

public extension GetFileGroupUseCase {
    func callAsFunction(mimeType: String) -> Entities.FileGroup {
        execute(mimeType: mimeType)
    }
}

public final class GetFileGroup: GetFileGroupUseCase {
    private let fileDecoder: any FileDecoderProtocol

    public init(fileDecoder: any FileDecoderProtocol = FileDecoder()) {
        self.fileDecoder = fileDecoder
    }

    public func execute(mimeType: String) -> Entities.FileGroup {
        fileDecoder.getFilegroupFromMimetype(mimetype: mimeType).toEntitiesFileGroup()
    }
}

private extension PassRustCore.FileGroup {
    // swiftlint:disable:next cyclomatic_complexity
    func toEntitiesFileGroup() -> Entities.FileGroup {
        switch self {
        case .image:
            .image
        case .photo:
            .photo
        case .vectorImage:
            .vectorImage
        case .video:
            .video
        case .audio:
            .audio
        case .key:
            .key
        case .text:
            .text
        case .calendar:
            .calendar
        case .pdf:
            .pdf
        case .word:
            .word
        case .powerPoint:
            .pdf
        case .excel:
            .excel
        case .document:
            .document
        case .unknown:
            .unknown
        }
    }
}
