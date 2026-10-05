//
// LocalAppPreferencesDatasourceTests.swift
// Proton Pass - Created on 03/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

@testable import Client
import Entities
import Foundation
import Testing

@Suite(.tags(.localDatasource))
final class LocalAppPreferencesDatasourceTests {
    private let suiteName = "LocalAppPreferencesDatasourceTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let sut: any LocalAppPreferencesDatasourceProtocol

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        sut = LocalAppPreferencesDatasource(userDefault: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func `preferences can be upserted, updated and removed`() throws {
        #expect(try sut.getPreferences() == nil)

        let givenPrefs = AppPreferences.random()
        try sut.upsertPreferences(givenPrefs)

        let result1 = try #require(try sut.getPreferences())
        #expect(result1 == givenPrefs)

        let updatedPrefs = AppPreferences.random()
        try sut.upsertPreferences(updatedPrefs)
        let result2 = try #require(try sut.getPreferences())
        #expect(result2 == updatedPrefs)

        sut.removePreferences()
        #expect(try sut.getPreferences() == nil)
    }
}
