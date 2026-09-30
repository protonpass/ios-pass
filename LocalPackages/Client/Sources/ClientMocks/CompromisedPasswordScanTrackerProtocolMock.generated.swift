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
import Foundation

public final class CompromisedPasswordScanTrackerProtocolMock: @unchecked Sendable, CompromisedPasswordScanTrackerProtocol {

    public init() {}

    // MARK: - isFullScanDue
    public var closureIsFullScanDue: () -> () = {}
    public var invokedIsFullScanDuefunction = false
    public var invokedIsFullScanDueCount = 0
    public var invokedIsFullScanDueParameters: (userId: String, Void)?
    public var invokedIsFullScanDueParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedIsFullScanDueResult: Bool!

    public func isFullScanDue(userId: String) -> Bool {
        invokedIsFullScanDuefunction = true
        invokedIsFullScanDueCount += 1
        invokedIsFullScanDueParameters = (userId, ())
        closureIsFullScanDue()
        return stubbedIsFullScanDueResult
    }
    // MARK: - isCorpusUnchanged
    public var closureIsCorpusUnchanged: () -> () = {}
    public var invokedIsCorpusUnchangedfunction = false
    public var invokedIsCorpusUnchangedCount = 0
    public var invokedIsCorpusUnchangedParameters: (userId: String, currentLastChange: Int)?
    public var invokedIsCorpusUnchangedParametersList = [(userId: String, currentLastChange: Int)]()
    public nonisolated(unsafe) var stubbedIsCorpusUnchangedResult: Bool!

    public func isCorpusUnchanged(userId: String, currentLastChange: Int) -> Bool {
        invokedIsCorpusUnchangedfunction = true
        invokedIsCorpusUnchangedCount += 1
        invokedIsCorpusUnchangedParameters = (userId, currentLastChange)
        closureIsCorpusUnchanged()
        return stubbedIsCorpusUnchangedResult
    }
    // MARK: - recordFullScan
    public var closureRecordFullScan: () -> () = {}
    public var invokedRecordFullScanfunction = false
    public var invokedRecordFullScanCount = 0
    public var invokedRecordFullScanParameters: (userId: String, Void)?
    public var invokedRecordFullScanParametersList = [(userId: String, Void)]()

    public func recordFullScan(userId: String) {
        invokedRecordFullScanfunction = true
        invokedRecordFullScanCount += 1
        invokedRecordFullScanParameters = (userId, ())
        closureRecordFullScan()
    }
    // MARK: - recordCorpusLastChange
    public var closureRecordCorpusLastChange: () -> () = {}
    public var invokedRecordCorpusLastChangefunction = false
    public var invokedRecordCorpusLastChangeCount = 0
    public var invokedRecordCorpusLastChangeParameters: (lastChange: Int, userId: String)?
    public var invokedRecordCorpusLastChangeParametersList = [(lastChange: Int, userId: String)]()

    public func recordCorpusLastChange(_ lastChange: Int, userId: String) {
        invokedRecordCorpusLastChangefunction = true
        invokedRecordCorpusLastChangeCount += 1
        invokedRecordCorpusLastChangeParameters = (lastChange, userId)
        closureRecordCorpusLastChange()
    }
}
