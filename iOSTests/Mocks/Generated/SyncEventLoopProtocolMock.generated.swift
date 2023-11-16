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

@testable import Client
import Combine
import Core
import Entities
import Foundation
import ProtonCoreNetworking
import Reachability

final class SyncEventLoopProtocolMock: @unchecked Sendable, SyncEventLoopProtocol {
    // MARK: - start
    var closureStart: () -> () = {}
    var invokedStart = false
    var invokedStartCount = 0

    func start() {
        invokedStart = true
        invokedStartCount += 1
        closureStart()
    }
    // MARK: - forceSync
    var closureForceSync: () -> () = {}
    var invokedForceSync = false
    var invokedForceSyncCount = 0

    func forceSync() {
        invokedForceSync = true
        invokedForceSyncCount += 1
        closureForceSync()
    }
    // MARK: - stop
    var closureStop: () -> () = {}
    var invokedStop = false
    var invokedStopCount = 0

    func stop() {
        invokedStop = true
        invokedStopCount += 1
        closureStop()
    }
    // MARK: - reset
    var closureReset: () -> () = {}
    var invokedReset = false
    var invokedResetCount = 0

    func reset() {
        invokedReset = true
        invokedResetCount += 1
        closureReset()
    }
}
