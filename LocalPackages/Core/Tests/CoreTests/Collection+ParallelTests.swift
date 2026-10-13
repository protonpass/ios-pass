//
// Collection+ParallelTests.swift
// Proton Pass - Created on 05/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Core
import Testing

private actor InFlightCounter {
    private var current = 0
    private(set) var max = 0

    func enter() {
        current += 1
        max = Swift.max(max, current)
    }

    func leave() {
        current -= 1
    }
}

private struct TransformError: Error {}

@Suite(.tags(.utilities))
struct CollectionParallelTests {
    @Test func `parallel map keeps the input order when later elements finish first`() async throws {
        let result = try await [5, 4, 3, 2, 1].parallelMap(parallelism: 5) { value in
            try await Task.sleep(for: .milliseconds(value * 10))
            return value * 2
        }

        #expect(result == [10, 8, 6, 4, 2])
    }

    @Test func `parallel map of an empty collection is empty`() async throws {
        let result = try await [Int]().parallelMap { $0 }
        #expect(result.isEmpty)
    }

    @Test func `parallel map rethrows the first transform error`() async {
        await #expect(throws: TransformError.self) {
            try await [1, 2, 3].parallelMap { value in
                if value == 2 { throw TransformError() }
                return value
            }
        }
    }

    @Test func `parallel map never runs more transforms at once than the requested parallelism`() async throws {
        let counter = InFlightCounter()

        _ = try await Array(0..<12).parallelMap(parallelism: 3) { value in
            await counter.enter()
            try await Task.sleep(for: .milliseconds(20))
            await counter.leave()
            return value
        }

        #expect(await counter.max <= 3)
    }

    @Test func `compact parallel map drops nil results`() async throws {
        let result = try await [1, 2, 3, 4, 5, 6].compactParallelMap(parallelism: 3) { value -> Int? in
            value.isMultiple(of: 2) ? value : nil
        }

        #expect(result.sorted() == [2, 4, 6])
    }

    @Test func `parallel each honours the requested parallelism`() async throws {
        let counter = InFlightCounter()

        try await Array(0..<8).parallelEach(parallelism: 4) { _ in
            await counter.enter()
            try await Task.sleep(for: .milliseconds(100))
            await counter.leave()
        }

        let maxInFlight = await counter.max
        #expect(maxInFlight > 2)
        #expect(maxInFlight <= 4)
    }
}
