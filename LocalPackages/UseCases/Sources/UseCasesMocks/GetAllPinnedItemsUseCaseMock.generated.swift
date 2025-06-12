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
import Client
import Combine
import Entities

public final class GetAllPinnedItemsUseCaseMock: @unchecked Sendable, GetAllPinnedItemsUseCase {

    public init() {}

    // MARK: - execute
    public var closureExecute1: () -> () = {}
    public var invokedExecute1 = false
    public var invokedExecuteCount1 = 0
    public var stubbedExecuteResult1: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>!

    public func execute() -> CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> {
        invokedExecute1 = true
        invokedExecuteCount1 += 1
        closureExecute1()
        return stubbedExecuteResult1
    }
    // MARK: - execute
    public var executeThrowableError2: Error?
    public var closureExecuteAsync2: () -> () = {}
    public var invokedExecuteAsync2 = false
    public var invokedExecuteAsyncCount2 = 0
    public var stubbedExecuteAsyncResult2: [SymmetricallyEncryptedItem]!

    public func execute() async throws -> [SymmetricallyEncryptedItem] {
        invokedExecuteAsync2 = true
        invokedExecuteAsyncCount2 += 1
        if let error = executeThrowableError2 {
            throw error
        }
        closureExecuteAsync2()
        return stubbedExecuteAsyncResult2
    }
}
