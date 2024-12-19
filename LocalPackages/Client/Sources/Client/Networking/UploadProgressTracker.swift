//
// UploadProgressTracker.swift
// Proton Pass - Created on 19/12/2024.
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

public final class UploadProgressTracker: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private var totalBytes: Int64
    private var bytesSent: Int64 = 0
    public var onUpdateProgress: (Float) -> Void

    public init(totalBytes: Int64,
                onUpdateProgress: @escaping (Float) -> Void) {
        assert(totalBytes > 0, "Size must be greater than 0 in order to track progress")
        // Best effort to make sure totalBytes is always greater than 0 to avoid crash
        // (can not divide by 0)
        self.totalBytes = max(1, totalBytes)
        self.onUpdateProgress = onUpdateProgress
    }

    public nonisolated func urlSession(_ session: URLSession,
                                       task: URLSessionTask,
                                       didSendBodyData bytesSent: Int64,
                                       totalBytesSent: Int64,
                                       totalBytesExpectedToSend: Int64) {
        self.bytesSent += bytesSent
        onUpdateProgress(Float(self.bytesSent) / Float(totalBytes))
    }
}
