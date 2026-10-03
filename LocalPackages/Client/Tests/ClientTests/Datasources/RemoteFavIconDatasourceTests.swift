//
// RemoteFavIconDatasourceTests.swift
// Proton Pass - Created on 14/04/2023.
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
import Combine
import Core
import Foundation
import ProtonCoreServices
import Testing

final class APIManagerProtocolMock: APIManagerProtocol {
    let apiServiceWereUpdated: PassthroughSubject<any APIService, Never> = .init()

    func getApiService(userId: String) -> any APIService {
        PMAPIService.dummyService()
    }
    
    func getUnauthApiService() -> any APIService {
        PMAPIService.dummyService()
    }
    
    func reset() {}

    func removeApiService(for userId: String) {}
}

@Suite(.tags(.remoteDatasource))
struct RemoteFavIconDatasourceTests {
    let sut = RemoteFavIconDatasource(apiServicing: APIManagerProtocolMock())
}

extension RemoteFavIconDatasourceTests {
    @Test func `returns the data when status code is 200 and data is present`() throws {
        // Given
        let givenData = try Data.random()
        let givenDataResponse = DataResponse.random(statusCode: 200, protonCode: nil, data: givenData)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        guard case let .positive(data) = result else {
            Issue.record("Should have positive result")
            return
        }
        #expect(data == givenData)
    }

    @Test(arguments: [200, 204])
    func `returns not exist when data is nil for a success status code`(statusCode: Int) throws {
        // Given
        let givenDataResponse = DataResponse.random(statusCode: statusCode, protonCode: nil, data: nil)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        guard case .negative(.notExist) = result else {
            Issue.record("Should be \"not exist\"")
            return
        }
    }

    @Test(arguments: [205, 400, 500], FavIconError.allCases)
    func `returns the known error for an unsuccessful status code`(statusCode: Int,
                                                                   givenError: FavIconError) throws {
        // Given
        let givenDataResponse = DataResponse.random(statusCode: statusCode,
                                                    protonCode: givenError.rawValue,
                                                    data: nil)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        guard case let .negative(.error(error)) = result else {
            Issue.record("Should be a known error")
            return
        }
        #expect(error == givenError)
    }

    @Test func `throws when both status code and proton code are unknown`() {
        // Given
        let givenDataResponse = DataResponse.random(statusCode: .random(in: 1_000...Int.max),
                                                    protonCode: .random(in: 10_000...Int.max),
                                                    data: nil)

        // When / Then
        #expect(throws: (any Error).self) {
            try sut.handle(dataResponse: givenDataResponse)
        }
    }
}

private extension DataResponse {
    static func random(statusCode: Int, protonCode: Int?, data: Data?) -> DataResponse {
        .init(httpCode: statusCode,
              protonCode: protonCode,
              data: data)
    }
}
