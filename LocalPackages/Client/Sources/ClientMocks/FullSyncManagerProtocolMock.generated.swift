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

@MainActor
public final class FullSyncManagerProtocolMock: @unchecked Sendable, FullSyncManagerProtocol {

    public init() {}

    // MARK: - start
    public var closureStart: () -> () = {}
    public var invokedStartfunction = false
    public var invokedStartCount = 0
    public var invokedStartParameters: (userId: String, presentation: FullSyncPresentation)?
    public var invokedStartParametersList = [(userId: String, presentation: FullSyncPresentation)]()
    public nonisolated(unsafe) var stubbedStartResult: FullSyncOperation!

    public func start(userId: String, presentation: FullSyncPresentation) -> FullSyncOperation {
        invokedStartfunction = true
        invokedStartCount += 1
        invokedStartParameters = (userId, presentation)
        closureStart()
        return stubbedStartResult
    }
    // MARK: - cancel
    public var closureCancel: () -> () = {}
    public var invokedCancelfunction = false
    public var invokedCancelCount = 0
    public var invokedCancelParameters: (userId: String, Void)?
    public var invokedCancelParametersList = [(userId: String, Void)]()

    public func cancel(userId: String) async {
        invokedCancelfunction = true
        invokedCancelCount += 1
        invokedCancelParameters = (userId, ())
        closureCancel()
    }
    // MARK: - reset
    public var closureReset: () -> () = {}
    public var invokedResetfunction = false
    public var invokedResetCount = 0

    public func reset() async {
        invokedResetfunction = true
        invokedResetCount += 1
        closureReset()
    }
}
