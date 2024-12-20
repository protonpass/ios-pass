//
// DownloadProgressTracker.swift
// Proton Pass - Created on 20/12/2024.
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

public final class DownloadProgressTracker: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    public var onUpdateProgress: (Float) -> Void

    public init(onUpdateProgress: @escaping (Float) -> Void) {
        self.onUpdateProgress = onUpdateProgress
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        // Not applicable
    }

    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        onUpdateProgress(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
    }
}
