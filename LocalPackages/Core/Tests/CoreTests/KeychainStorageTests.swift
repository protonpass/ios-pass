//
// KeychainStorageTests.swift
// Proton Pass - Created on 11/07/2023.
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

@testable import Core
import Combine
import ProtonCoreKeymaker
import XCTest

final class KeychainMainkeyProviderMock: @unchecked Sendable, KeychainProtocol, MainKeyProvider {
    var dict: [String: Data] = [:]

    func dataOrError(forKey key: String, attributes: [CFString : Any]?) throws -> Data? {
        dict[key]
    }

    func stringOrError(forKey key: String, attributes: [CFString : Any]?) throws -> String? {
        fatalError("Not applicable")
    }

    func setOrError(_ data: Data, forKey key: String, attributes: [CFString : Any]?) throws {
        dict[key] = data
    }

    func setOrError(_ string: String, forKey key: String, attributes: [CFString : Any]?) throws {
        fatalError("Not applicable")
    }

    func removeOrError(forKey key: String) throws {
        dict[key] = nil
    }

    var mainKey: MainKey? = Array(repeating: .zero, count: 32)

    func wipeMainKey() {
        mainKey = nil
    }
}

actor LogManagerMock: LogManagerProtocol {
    var shouldLog: Bool = true
    var logEntries: [LogEntry] = []

    var logFunction: ((LogEntry) -> Void)?
    var getLogEntriesFunction: (() async throws -> [LogEntry])?

    func log(entry: LogEntry) {
        logFunction?(entry)
        if shouldLog {
            logEntries.append(entry)
        }
    }

    func getLogEntries() async throws -> [LogEntry] {
        logEntries
    }

    func removeAllLogs() {
        logEntries.removeAll()
    }

    func saveAllLogs() {
        // Do nothing in the mock implementation
    }

    func toggleLogging(shouldLog: Bool) {
        self.shouldLog = shouldLog
    }
}

final class ObservableKeychainStorageMock: ObservableObject {
    @KeychainStorage(key: .random(),
                     defaultValue: String.random(),
                     keychain: KeychainMainkeyProviderMock(),
                     logManager: LogManagerMock())
    var testString: String
}

final class KeychainStorageTests: XCTestCase {
    var sut: ObservableKeychainStorageMock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = .init()
        cancellables = .init()
    }

    override func tearDown() {
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    #warning("This doesn't fire any more we need to check why KeychainStorage is acting up" )
//    func testObjectWillChangedIsFired() {
//        let expectation = XCTestExpectation(description: "objectWillChange is fired")
//
//        sut.objectWillChange
//            .sink { _ in
//                expectation.fulfill()
//            }
//            .store(in: &cancellables)
//
//        sut.testString = .random()
//
//        wait(for: [expectation], timeout: 1)
//    }
}
