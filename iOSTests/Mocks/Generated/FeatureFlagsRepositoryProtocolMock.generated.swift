// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
// swiftlint:disable all

@testable import Proton_Pass
import Core

final class FeatureFlagsRepositoryProtocolMock: @unchecked Sendable, FeatureFlagsRepositoryProtocol {
    // MARK: - getFlags
    var getFlagsThrowableError: Error?
    var closureGetFlags: () -> () = {}
    var invokedGetFlags = false
    var invokedGetFlagsCount = 0
    var stubbedGetFlagsResult: FeatureFlags!

    func getFlags() async throws -> FeatureFlags {
        invokedGetFlags = true
        invokedGetFlagsCount += 1
        if let error = getFlagsThrowableError {
            throw error
        }
        closureGetFlags()
        return stubbedGetFlagsResult
    }
    // MARK: - refreshFlags
    var refreshFlagsThrowableError: Error?
    var closureRefreshFlags: () -> () = {}
    var invokedRefreshFlags = false
    var invokedRefreshFlagsCount = 0
    var stubbedRefreshFlagsResult: FeatureFlags!

    func refreshFlags() async throws -> FeatureFlags {
        invokedRefreshFlags = true
        invokedRefreshFlagsCount += 1
        if let error = refreshFlagsThrowableError {
            throw error
        }
        closureRefreshFlags()
        return stubbedRefreshFlagsResult
    }
}
