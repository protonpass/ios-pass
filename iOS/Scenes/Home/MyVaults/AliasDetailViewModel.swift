//
// AliasDetailViewModel.swift
// Proton Pass - Created on 15/09/2022.
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

enum AliasState {
    case loading
    case loaded(Alias)
    case error(Error)

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
}

final class AliasDetailViewModel: BaseItemDetailViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var name = ""
    @Published private(set) var note = ""
    @Published private(set) var aliasState: AliasState = .loading

    private let aliasRepository: AliasRepositoryProtocol

    init(itemContent: ItemContent,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol) {
        self.aliasRepository = aliasRepository
        super.init(itemContent: itemContent, itemRepository: itemRepository)
        getAlias()
    }

    override func bindValues() {
        if case .alias = itemContent.contentData {
            self.name = itemContent.name
            self.note = itemContent.note
        } else {
            fatalError("Expecting alias type")
        }
    }

    func getAlias() {
        Task { @MainActor in
            do {
                aliasState = .loading
                let alias = try await aliasRepository.getAliasDetails(shareId: itemContent.shareId,
                                                                      itemId: itemContent.itemId)
                aliasState = .loaded(alias)
            } catch {
                aliasState = .error(error)
            }
        }
    }
}
