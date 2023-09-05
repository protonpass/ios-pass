//
// Publisher+Unwrap.swift
// Proton Pass - Created on 20/06/2022.
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

import Combine

public protocol OptionalType {
    associatedtype Wrapped

    var value: Wrapped? { get }
}

extension Optional: OptionalType {
    public var value: Wrapped? { self }
}

/// Unwrapping an optional type operator
public extension Publishers {
    struct Unwrapped<Upstream>: Publisher where Upstream: Publisher, Upstream.Output: OptionalType {
        public typealias Output = Upstream.Output.Wrapped
        public typealias Failure = Upstream.Failure

        /// The publisher from which this publisher receives elements.
        public let upstream: AnyPublisher<Upstream.Output.Wrapped, Upstream.Failure>

        public init(upstream: Upstream) {
            self.upstream = upstream
                .flatMap { optional -> AnyPublisher<Output, Failure> in
                    guard let unwrapped = optional.value else {
                        return Empty().eraseToAnyPublisher()
                    }
                    return Result.Publisher(unwrapped).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }

        public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            upstream.receive(subscriber: subscriber)
        }
    }
}

public extension Publisher where Output: OptionalType {
    func unwrap() -> Publishers.Unwrapped<Self> {
        Publishers.Unwrapped(upstream: self)
    }
}
