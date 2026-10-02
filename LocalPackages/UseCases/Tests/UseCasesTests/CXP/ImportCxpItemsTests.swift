//
// ImportCxpItemsTests.swift
// Proton Pass - Created on 02/10/2026.
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

import ClientMocks
import Entities
import EntitiesMocks
import Foundation
import os
import Testing
import UseCases

@Suite(.tags(.cxp))
struct ImportCxpItemsTests {
    let shareRepository = ShareRepositoryProtocolMock()
    let itemRepository = ItemRepositoryProtocolMock()
    let sut: any ImportCxpItemsUseCase

    init() {
        shareRepository.stubbedCreateVaultResult = .random(shareID: "share")
        itemRepository.stubbedImportItemsOnProgressResult = (1, ())
        sut = ImportCxpItems(shareRepository: shareRepository, itemRepository: itemRepository)
    }

    @Test
    func `create one vault per collection and skip empty ones`() async throws {
        let result = CxpImportResult(exporterName: "Exporter",
                                     vaults: [
                                         .init(vault: .init(name: "Personal",
                                                            description: "",
                                                            color: .color2,
                                                            icon: .icon2),
                                               items: [.note(name: "Note 1"), .note(name: "Note 2")]),
                                         .init(vault: .init(name: "Empty",
                                                            description: "",
                                                            color: .color1,
                                                            icon: .icon1),
                                               items: []),
                                         .init(vault: nil, items: [.note(name: "Note 3")])
                                     ])
        let progress = OSAllocatedUnfairLock(initialState: [Int]())

        try await sut(userId: "user", result: result) { count in
            progress.withLock { $0.append(count) }
        }

        #expect(await shareRepository.invokedCreateVaultCount == 2)
        let lastVaultName = await shareRepository.invokedCreateVaultParameters?.vault.name
        #expect(lastVaultName?.hasPrefix("Imported on ") == true)
        #expect(itemRepository.invokedImportItemsCount == 2)
        #expect(itemRepository.invokedImportItemsParameters?.contents.map(\.name) == ["Note 3"])
        #expect(progress.withLock { $0 } == [1, 3])
    }
}

private extension ItemContentProtobuf {
    static func note(name: String) -> Self {
        .init(name: name, note: "", itemUuid: UUID().uuidString, data: .note, customFields: [])
    }
}
