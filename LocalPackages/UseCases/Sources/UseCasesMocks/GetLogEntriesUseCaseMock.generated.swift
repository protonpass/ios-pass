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

import UseCases
import Core
import Entities

public final class GetLogEntriesUseCaseMock: @unchecked Sendable, GetLogEntriesUseCase {

    public init() {}

    // MARK: - execute
    public var executeForThrowableError1: Error?
    public var closureExecute: () -> () = {}
    public var invokedExecutefunction = false
    public var invokedExecuteCount = 0
    public var invokedExecuteParameters: (module: PassModule, Void)?
    public var invokedExecuteParametersList = [(module: PassModule, Void)]()
    public var stubbedExecuteResult: [LogEntry]!

    public func execute(for module: PassModule) async throws -> [LogEntry] {
        invokedExecutefunction = true
        invokedExecuteCount += 1
        invokedExecuteParameters = (module, ())
        invokedExecuteParametersList.append((module, ()))
        if let error = executeForThrowableError1 {
            throw error
        }
        closureExecute()
        return stubbedExecuteResult
    }
}
