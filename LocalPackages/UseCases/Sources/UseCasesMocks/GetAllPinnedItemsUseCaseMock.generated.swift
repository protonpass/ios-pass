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

@testable import UseCases
import Client
import Combine
import Entities

public final class GetAllPinnedItemsUseCaseMock: @unchecked Sendable, GetAllPinnedItemsUseCase {

    public init() {}

    // MARK: - execute
    public var closureExecute: () -> () = {}
    public var invokedExecute = false
    public var invokedExecuteCount = 0
    public var stubbedExecuteResult: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>!

    public func execute() -> CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> {
        invokedExecute = true
        invokedExecuteCount += 1
        closureExecute()
        return stubbedExecuteResult
    }
    // MARK: - execute
    public var executeThrowableError: Error?
    public var closureExecuteAsync: () -> () = {}
    public var invokedExecuteAsync = false
    public var invokedExecuteAsyncCount = 0
    public var stubbedExecuteAsyncResult: [SymmetricallyEncryptedItem]!

    public func execute() async throws -> [SymmetricallyEncryptedItem] {
        invokedExecuteAsync = true
        invokedExecuteAsyncCount += 1
        if let error = executeThrowableError {
            throw error
        }
        closureExecuteAsync()
        return stubbedExecuteAsyncResult
    }
}
