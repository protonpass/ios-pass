//
// SanitizeFileNameTests.swift
// Proton Pass - Created on 22/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Testing
import UseCases

@Suite(.tags(.useCase))
struct SanitizeFileNameTests {
    let sut: any SanitizeFileNameUseCase = SanitizeFileName()

    @Test(arguments: [
        "My report [final] #2 100%.pdf",
        "café.txt",
        "Lønseddel.pdf",
        "Screenshot 2026-10-05 at 1.47.07\u{202F}PM.png",
        "测试报告.txt",
        "😀 emoji.png"
    ])
    func `keeps names that are valid file names`(fileName: String) {
        #expect(sut(fileName) == fileName)
    }

    @Test(arguments: [
        ("../../secret.txt", "....secret.txt"),
        ("folder/report.pdf", "folderreport.pdf"),
        ("C:\\report.pdf", "Creport.pdf"),
        ("line\nbreak.txt", "linebreak.txt")
    ])
    func `removes characters that could escape the attachment folder`(fileName: String, expected: String) {
        #expect(sut(fileName) == expected)
    }
}
