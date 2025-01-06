//
// AsyncThrowingStream+Extensions.swift
// Proton Pass - Created on 04/01/2025.
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

import Foundation

/// `AsyncThrowingStream` continuation base with async closure support
public extension AsyncThrowingStream where Failure == Error {
    static func asyncContinuation(_ block:
        @Sendable @escaping (Continuation) async throws -> Void) -> Self {
        AsyncThrowingStream<Element, Failure>(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                do {
                    try await block(continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                if !task.isCancelled {
                    print("Cancelling AsyncStream inner task")
                    task.cancel()
                }
            }
        }
    }
}
