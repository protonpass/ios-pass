//
// FileProgressTracker.swift
// Proton Pass - Created on 03/01/2024.
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

import Foundation

// Track file download and upload progress
public actor FileProgressTracker {
    private let size: Int
    private var processedBytesCount = 0

    public init(size: Int) {
        self.size = max(1, size)
    }

    public func overallProgress(currentProgress: Float, chunkSize: Int) -> Float {
        let recentlyProcessed = currentProgress * Float(chunkSize)
        let progress = (Float(processedBytesCount) + recentlyProcessed) / Float(size)
        if currentProgress >= 1.0 {
            // Chunk is completely downloaded/uploaded
            processedBytesCount += Int(recentlyProcessed)
        }
        return progress
    }
}
