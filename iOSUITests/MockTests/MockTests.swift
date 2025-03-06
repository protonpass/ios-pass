//
// ProxyTest.swift
// Proton Pass - Created on 2025. 02. 25..
// Copyright (c) 2025 Proton Technologies AG
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

import XCTest
import ProtonCoreTestingToolkitProxy
import ProtonCoreTestingToolkitUITestsLogin

final class MockTests: LoginBaseTestCase {

    private let defaultTimeout: TimeInterval = 25.0

    // when you record a user the password should be password
    func testMockLoginEmptyUser() throws {
        mocking()

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: "whatever",
                               password: "password",
                               loginRobot: WelcomeRobot().logIn(),
                               retRobot: GetStartedRobot.self)
            .tapClose()
            .tapProfile()
    }

    private func mocking() {
        let resetStaticMocks = self.expectation(description:"Reset static mocks")
        let expectationsrp = self.expectation(description:"Fetch scenarios")
        let parameters: [String: Any] = [
            "UserID": "kmehyJpxDjGQdmwx87J4BQrxqjlPwgYZ_A2lWOWjWOaaut1aTvso_Dg_KS1Z13SVp-dNzvKz1cMEbUyOULkW5g=="
        ] // should match with the mock
        let dynamicMock = DynamicMockBody(name: "loginWithSrp", enabled: true, parameters: AnyCodable(value: parameters))

        client.resetStaticMocks { result in
            switch result {
            case .success(_):
                print("Reset static mocks Success \n")
            case .failure(let error):
                XCTFail("Failed to fetch scenarios: \(error)")
            }
            resetStaticMocks.fulfill()
        }
        wait(for: [resetStaticMocks], timeout: defaultTimeout)

        client.addDynamicMockScenario(dynamicMock: dynamicMock) { result in
            switch result {
            case .success(_):
                print("Enable loginWithSrp \n")
            case .failure(let error):
                XCTFail("Failed to fetch scenarios: \(error)")
            }
            expectationsrp.fulfill()
        }
        wait(for: [expectationsrp], timeout: defaultTimeout)

        let subdirectory = "scenarios"
        let filename = "empty-login-scenario.json"
        loadScenarioFile(subdirectory: subdirectory, filename: filename)
        let disableForwardExpectation = self.expectation(description: "Disable forward")

        client.setMockForwardingStatus(requestForward: RequestForward(enabled: false), completion: { result in
            switch result {
            case .success(let forward):
                XCTAssertFalse(forward.enabled, "The forward should be disabled.")
            case .failure(let error):
                XCTFail("Failed to fetch scenarios: \(error)")
            }
            disableForwardExpectation.fulfill()
        })

        wait(for: [disableForwardExpectation], timeout: defaultTimeout)

    }

    private func loadScenarioFile(subdirectory: String, filename: String) {
        let bulkRouteExpectation = expectation(description: "Set bulk routes from scenario file")

        let bundle = Bundle(for: Self.self)

        do {
            let scenarioFileWithName = try ScenarioDataFactory.readScenarioFile(filename: filename, subdirectory: subdirectory, bundle: bundle)
            let routes = try ScenarioDataFactory.parseScenarioFile(from: scenarioFileWithName, bundle: bundle)
            client.updateStaticMockRoutes(routes: routes) { result in
                switch result {
                case .success(let routeDataArray):
                    XCTAssertEqual(routeDataArray.count, routes.count, "Expected the number of routes to match the input file.")
                case .failure(let error):
                    XCTFail("Failed to set bulk routes from scenario file: \(error)")
                }

                bulkRouteExpectation.fulfill()
            }

        } catch ScenarioDataError.missingFile(let message) {
            XCTFail("Error: Missing file - \(message)")
        } catch ScenarioDataError.jsonParsingError(let message) {
            XCTFail("Error: JSON Parsing failed - \(message)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        wait(for: [bulkRouteExpectation], timeout: 30)
    }
}
