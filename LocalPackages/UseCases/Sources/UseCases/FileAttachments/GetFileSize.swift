//
// GetFileSize.swift
// Proton Pass - Created on 02/12/2024.
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

public protocol GetFileSizeUseCase: Sendable {
    func execute(for url: URL) throws -> UInt64
}

public extension GetFileSizeUseCase {
    func callAsFunction(for url: URL) throws -> UInt64 {
        try execute(for: url)
    }
}

public final class GetFileSize: GetFileSizeUseCase {
    public init() {}

    public func execute(for url: URL) throws -> UInt64 {
        // Optionally access security scoped resource and continue
        // the flow even though the access fails because not all URLs are scoped
        // So we ignore the result of `startAccessingSecurityScopedResource`
        _ = url.startAccessingSecurityScopedResource()
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        let fileHandle = try FileHandle(forReadingFrom: url)
        let fileSize = try fileHandle.seekToEnd()
        try fileHandle.close()
        return fileSize
    }
}
