// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import Core
import CryptoKit
import Entities
import Foundation

public final class CompromisedPasswordCheckerProtocolMock: @unchecked Sendable, CompromisedPasswordCheckerProtocol {

    public init() {}

    // MARK: - check
    public var closureCheck: () -> () = {}
    public var invokedCheckfunction = false
    public var invokedCheckCount = 0
    public var invokedCheckParameters: (userId: String, candidates: [CompromisedPasswordCandidate])?
    public var invokedCheckParametersList = [(userId: String, candidates: [CompromisedPasswordCandidate])]()
    public nonisolated(unsafe) var stubbedCheckResult: [String: CompromisedPasswordResult]!

    public func check(userId: String, candidates: [CompromisedPasswordCandidate]) async -> [String: CompromisedPasswordResult] {
        invokedCheckfunction = true
        invokedCheckCount += 1
        invokedCheckParameters = (userId, candidates)
        closureCheck()
        return stubbedCheckResult
    }
}
