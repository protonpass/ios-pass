//
// Collection+ParallelMap.swift
// Proton Pass - Created on 22/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public extension Collection where Element: Sendable {
    func parallelMap<T: Sendable>(parallelism: Int = 2,
                                  _ transform: @escaping @Sendable (Element) async throws -> T) async rethrows
        -> [T] {
        guard !isEmpty else { return [] }

        var iterator = enumerated().makeIterator()

        return try await withThrowingTaskGroup(of: (Int, T).self, returning: [T].self) { group in
            var results = [T?](repeating: nil, count: count)

            // Submit initial tasks
            for _ in 0..<Swift.min(parallelism, count) {
                if let (index, element) = iterator.next() {
                    group.addTask {
                        let value = try await transform(element)
                        return (index, value)
                    }
                }
            }

            // Process completed tasks and submit new ones
            while let (index, value) = try await group.next() {
                results[index] = value

                if let (nextIndex, nextElement) = iterator.next() {
                    group.addTask {
                        let transformedValue = try await transform(nextElement)
                        return (nextIndex, transformedValue)
                    }
                }

                try Task.checkCancellation()
            }

            return results.compactMap { $0 }
        }
    }

    // periphery:ignore
    func parallelEach(parallelism requestedParallelism: Int? = nil,
                      _ work: @escaping @Sendable (Element) async throws -> Void) async rethrows {
        _ = try await parallelMap {
            try await work($0)
        }
    }

    func compactParallelMap<T: Sendable>(parallelism: Int = 2,
                                         _ transform: @escaping @Sendable (Element) async throws
                                             -> T?) async rethrows -> [T] {
        guard !isEmpty else { return [] }

        var iterator = makeIterator()

        return try await withThrowingTaskGroup(of: T?.self, returning: [T].self) { group in
            var results = [T]()

            // Submit initial tasks
            for _ in 0..<Swift.min(parallelism, count) {
                if let element = iterator.next() {
                    group.addTask {
                        try await transform(element)
                    }
                }
            }

            // Process completed tasks and submit new ones
            while let transformedValue = try await group.next() {
                if let value = transformedValue {
                    results.append(value)
                }

                if let nextElement = iterator.next() {
                    group.addTask {
                        try await transform(nextElement)
                    }
                }

                try Task.checkCancellation()
            }

            return results
        }
    }
}
