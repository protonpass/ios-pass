//
// GetMimeType.swift
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
import Foundation
@preconcurrency import PassRustCore

public protocol GetMimeTypeUseCase: Sendable {
    func execute(of url: URL, byteCount: Int) throws -> String
}

public extension GetMimeTypeUseCase {
    func callAsFunction(of url: URL, byteCount: Int = 100) throws -> String {
        try execute(of: url, byteCount: byteCount)
    }
}

public final class GetMimeType: GetMimeTypeUseCase {
    private let fileDecoder: any FileDecoderProtocol

    public init(fileDecoder: any FileDecoderProtocol = FileDecoder()) {
        self.fileDecoder = fileDecoder
    }

    public func execute(of url: URL, byteCount: Int) throws -> String {
        let fileHandle = try FileHandle(forReadingFrom: url)
        guard let data = try fileHandle.read(upToCount: byteCount) else {
            throw PassError.fileAttachment(.noDataFound(url))
        }
        return fileDecoder.getMimetypeFromContent(content: data)
    }
}
