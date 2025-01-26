//
// ParseCsvLoginsTests.swift
// Proton Pass - Created on 26/01/2025.
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

import Entities
import Testing
import UseCases

struct ParseCsvLoginsTests {
    let sut: any ParseCsvLoginsUseCase

    init() {
        sut = ParseCsvLogins()
    }

    @Test("Invalid number of column")
    func invalidNumberOfColumn() async throws {
        // Given
        let csv = """
        name,url,username,password,other
        proton.me,https://account.proton.me/switch,nobody@proton.me,proton123
        missing url,,missingurl@proton.me,proton123
        missing password,https://account.proton.me/switch,missingpw,
        broken url,htt:/proton.me/switch,brokenurl@proton.me,
        """

        await #expect(throws: PassError.csv(.invalidNumberOfColumn(5))) {
            try await sut(csv)
        }
    }

    @Test("Unexpected column name")
    func unexpectedColumName() async throws {
        // Given
        let csv = """
        name,url,email,password
        proton.me,https://account.proton.me/switch,nobody@proton.me,proton123
        missing url,,missingurl@proton.me,proton123
        missing password,https://account.proton.me/switch,missingpw,
        broken url,htt:/proton.me/switch,brokenurl@proton.me,
        """

        await #expect(throws: PassError.csv(.unexpectedColumnName(index: 2,
                                                                  expectation: "username",
                                                                  value: "email"))) {
            try await sut(csv)
        }
    }

    @Test("Invalid row")
    func invalidRow() async throws {
        // Given
        let csv = """
        name,url,username,password
        proton.me,https://account.proton.me/switch,nobody@proton.me,proton123
        missing url,,missingurl@proton.me,proton123
        missing password,https://account.proton
        broken url,htt:/proton.me/switch,brokenurl@proton.me,
        """

        await #expect(throws: PassError.csv(.invalidRow(3))) {
            try await sut(csv)
        }
    }

    @Test("Success")
    func success() async throws {
        // Given
        let csv = """
        name,url,username,password
        proton.me,https://account.proton.me/switch,nobody@proton.me,proton123
        missing url,,missingurl@proton.me,"proton, 123"
        missing password,https://account.proton.me/switch,missingpw,
        broken url,htt:/proton.me/switch,brokenurl@proton.me,
        """

        // When
        let logins = try await sut(csv)

        // Then
        #expect(logins.count == 4)

        #expect(logins[0].name == "proton.me")
        #expect(logins[0].url == "https://account.proton.me/switch")
        #expect(logins[0].email == "nobody@proton.me")
        #expect(logins[0].username.isEmpty)
        #expect(logins[0].password == "proton123")

        #expect(logins[1].name == "missing url")
        #expect(logins[1].url.isEmpty)
        #expect(logins[1].email == "missingurl@proton.me")
        #expect(logins[1].username.isEmpty)
        #expect(logins[1].password == "proton, 123")

        #expect(logins[2].name == "missing password")
        #expect(logins[2].url == "https://account.proton.me/switch")
        #expect(logins[2].email.isEmpty)
        #expect(logins[2].username == "missingpw")
        #expect(logins[2].password.isEmpty)

        #expect(logins[3].name == "broken url")
        #expect(logins[3].url == "htt:/proton.me/switch")
        #expect(logins[3].email == "brokenurl@proton.me")
        #expect(logins[3].username.isEmpty)
        #expect(logins[3].password.isEmpty)
    }
}
