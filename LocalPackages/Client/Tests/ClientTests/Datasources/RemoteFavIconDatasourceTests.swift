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
import ProtonCoreServices
import XCTest

final class APIManagerProtocolMock: APIManagerProtocol {
    let apiServiceWereUpdated: PassthroughSubject<any APIService, Never> = .init()

    func getApiService(userId: String) throws -> any APIService {
        PMAPIService.dummyService()
    }
    
    func getUnauthApiService() -> any APIService {
        PMAPIService.dummyService()
    }
    
    func reset() {
        
    }
    
    func removeApiService(for userId: String) {
        
    }
}

final class RemoteFavIconDatasourceTests: XCTestCase {
    var sut: RemoteFavIconDatasource!

    override func setUp() {
        super.setUp()
        sut = RemoteFavIconDatasource(apiServicing: APIManagerProtocolMock())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension RemoteFavIconDatasourceTests {
    func testReturnPositiveWhenStatusCode200AndDataNotNil() async throws {
        // Given
        let givenData = try Data.random()
        let givenDataResponse = DataResponse.random(statusCode: 200, protonCode: nil, data: givenData)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        switch result {
        case let .positive(data):
            let data = try XCTUnwrap(data)
            XCTAssertEqual(data, givenData)
        case .negative:
            XCTFail("Should have positive result")
        }
    }

    func testReturnNegativeWhenStatusCode200AndDataNil() throws {
        // Given
        let expectation = expectation(description: "Should be \"not exist\"")
        let givenDataResponse = DataResponse.random(statusCode: 200, protonCode: nil, data: nil)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        switch result {
        case .positive:
            XCTFail("Should have negative result")
        case let .negative(reason):
            switch reason {
            case .notExist:
                expectation.fulfill()
            case .error:
                XCTFail("Should be \"not exist\"")
            }
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReturnNegativeWhenStatusCode204AndDataNil() throws {
        // Given
        let expectation = expectation(description: "Should be \"not exist\"")
        let givenDataResponse = DataResponse.random(statusCode: 204, protonCode: nil, data: nil)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        switch result {
        case .positive:
            XCTFail("Should have negative result")
        case let .negative(reason):
            switch reason {
            case .notExist:
                expectation.fulfill()
            case .error:
                XCTFail("Should be \"not exist\"")
            }
        }
        wait(for: [expectation], timeout: 1)
    }

    func testReturnNegativeWhenStatusCodeNot200Or204ButWithKnownError() async throws {
        // Given
        let givenError = FavIconError.allCases.randomElement() ?? .invalidAddress
        let givenDataResponse = DataResponse.random(statusCode: .random(in: 205...Int.max),
                                                    protonCode: givenError.rawValue,
                                                    data: nil)

        // When
        let result = try sut.handle(dataResponse: givenDataResponse)

        // Then
        switch result {
        case .positive:
            XCTFail("Should have negative result")
        case let .negative(reason):
            switch reason {
            case .notExist:
                XCTFail("Should be a known error")
            case let .error(error):
                XCTAssertEqual(error, givenError)
            }
        }
    }

    func testThrowErrorWhenHttpStatusCodeAndErrorsAreNotKnown() throws {
        // Given
        let expectation = expectation(description: "Should throw an error")
        let givenDataResponse = DataResponse.random(statusCode: .random(in: 1_000...Int.max),
                                                    protonCode: .random(in: 10_000...Int.max),
                                                    data: nil)

        // When
        do {
            _ = try sut.handle(dataResponse: givenDataResponse)
        } catch {
            // Then
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

private extension DataResponse {
    static func random(statusCode: Int, protonCode: Int?, data: Data?) -> DataResponse {
        .init(httpCode: statusCode,
              protonCode: protonCode,
              data: data)
    }
}
