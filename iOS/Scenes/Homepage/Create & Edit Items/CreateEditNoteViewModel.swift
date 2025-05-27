//
// CreateEditNoteViewModel.swift
// Proton Pass - Created on 25/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Client
import Core
import DocScanner
import Entities
import ProtonCoreLogin
import SwiftUI

final class CreateEditNoteViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var note = ""

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Share]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)

        scanResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] result in
                guard let self, let result else { return }
                if let document = result as? ScannedDocument {
                    transformIntoNote(document: document)
                } else {
                    assertionFailure("Expecting ScannedDocument as result")
                }
            }
            .store(in: &cancellables)
    }

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    override func bindValues() {
        switch mode {
        case let .create(_, type):
            if case let .note(title, note) = type {
                self.title = title
                self.note = note
            }

        case let .clone(itemContent), let .edit(itemContent):
            if case .note = itemContent.contentData {
                title = itemContent.name
                note = itemContent.note
            }
        }
    }

    override var itemContentType: ItemContentType { .note }

    var interpretor: any ScanInterpreting { ScanInterpreter() }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: note,
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.note,
                            customFields: customFields)
    }
}

private extension CreateEditNoteViewModel {
    func transformIntoNote(document: ScannedDocument) {
        let pageContents = document.scannedPages.map { page in
            page.text.reduce(into: "") { partialResult, next in
                partialResult = partialResult + "\n" + next
            }
        }

        for (index, content) in pageContents.enumerated() {
            note += content
            if index != pageContents.count - 1 {
                note += "\n\n"
            }
        }
    }
}
