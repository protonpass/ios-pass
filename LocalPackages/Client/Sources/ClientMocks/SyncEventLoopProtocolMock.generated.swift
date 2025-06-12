// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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
import Combine
import Core
import Foundation
import ProtonCoreNetworking

public final class SyncEventLoopProtocolMock: @unchecked Sendable, SyncEventLoopProtocol {

    public init() {}

    // MARK: - forceSync
    public var closureForceSync: () -> () = {}
    public var invokedForceSyncfunction = false
    public var invokedForceSyncCount = 0

    public func forceSync() {
        invokedForceSyncfunction = true
        invokedForceSyncCount += 1
        closureForceSync()
    }
    // MARK: - reset
    public var closureReset: () -> () = {}
    public var invokedResetfunction = false
    public var invokedResetCount = 0

    public func reset() {
        invokedResetfunction = true
        invokedResetCount += 1
        closureReset()
    }
    // MARK: - start
    public var closureStart: () -> () = {}
    public var invokedStartfunction = false
    public var invokedStartCount = 0

    public func start() {
        invokedStartfunction = true
        invokedStartCount += 1
        closureStart()
    }
    // MARK: - stop
    public var closureStop: () -> () = {}
    public var invokedStopfunction = false
    public var invokedStopCount = 0

    public func stop() {
        invokedStopfunction = true
        invokedStopCount += 1
        closureStop()
    }
    // MARK: - addAdditionalTask
    public var closureAddAdditionalTask: () -> () = {}
    public var invokedAddAdditionalTaskfunction = false
    public var invokedAddAdditionalTaskCount = 0
    public var invokedAddAdditionalTaskParameters: (task: SyncEventLoop.AdditionalTask, Void)?
    public var invokedAddAdditionalTaskParametersList = [(task: SyncEventLoop.AdditionalTask, Void)]()

    public func addAdditionalTask(_ task: SyncEventLoop.AdditionalTask) {
        invokedAddAdditionalTaskfunction = true
        invokedAddAdditionalTaskCount += 1
        invokedAddAdditionalTaskParameters = (task, ())
        invokedAddAdditionalTaskParametersList.append((task, ()))
        closureAddAdditionalTask()
    }
}
