//
// CreateEditAliasViewModel.swift
// Proton Pass - Created on 05/08/2022.
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
import ProtonCore_Login

final class CreateEditAliasViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var prefix = ""
    @Published var suffix = ""
    @Published var mailbox = ""
    @Published var note = ""

    let aliasRepository: AliasRepositoryProtocol

    init(mode: ItemMode,
         userData: UserData,
         shareRepository: ShareRepositoryProtocol,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol) {
        self.aliasRepository = aliasRepository
        super.init(mode: mode,
                   userData: userData,
                   shareRepository: shareRepository,
                   shareKeysRepository: shareKeysRepository,
                   itemRevisionRepository: itemRevisionRepository)
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "Create new alias"
        case .edit:
            return "Edit alias"
        }
    }
}
