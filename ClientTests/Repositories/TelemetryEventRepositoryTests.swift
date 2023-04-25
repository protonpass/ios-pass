//
// TelemetryEventRepositoryTests.swift
// Proton Pass - Created on 25/04/2023.
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

@testable import Client
import Core
import ProtonCore_Services
import XCTest

private final class MockedRemoteDatasource: RemoteTelemetryEventDatasourceProtocol {
    let apiService = PMAPIService.dummyService()

    func send(events: [EventInfo]) async throws {}
}

private final class MockedFreeUserPlanProvider: UserPlanProviderProtocol {
    let apiService = PMAPIService.dummyService()
    let logger = Logger.dummyLogger()

    func getUserPlan() async throws -> UserPlan { .free }
}

final class TelemetryEventRepositoryTests: XCTestCase {
    var sut: TelemetryEventRepositoryProtocol!

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension TelemetryEventRepositoryTests {
    func testAddNewEvents() async throws {
        let mockedLocalDatasource = LocalTelemetryEventDatasource(
            container: .Builder.build(name: kProtonPassContainerName, inMemory: true))
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    preferences: .init())

        // Given
        sut = TelemetryEventRepository(localTelemetryEventDatasource: mockedLocalDatasource,
                                       remoteTelemetryEventDatasource: MockedRemoteDatasource(),
                                       userPlanProvider: MockedFreeUserPlanProvider(),
                                       eventCount: 100,
                                       logManager: .dummyLogManager(),
                                       scheduler: telemetryScheduler)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))
        let events = try await mockedLocalDatasource.getOldestEvents(count: 100)

        // Then
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[0].type, .create(.login))
        XCTAssertEqual(events[1].type, .read(.alias))
        XCTAssertEqual(events[2].type, .update(.note))
        XCTAssertEqual(events[3].type, .delete(.login))
    }
}
