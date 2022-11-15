//
// MyVaultsViewModel.swift
// Proton Pass - Created on 18/07/2022.
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
import Combine
import Core
import SwiftUI

final class MyVaultsViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    private let vaultSelection: VaultSelection
    private var cancellables = Set<AnyCancellable>()

    var vaults: [VaultProtocol] { vaultSelection.vaults }

    init(vaultSelection: VaultSelection) {
        self.vaultSelection = vaultSelection
        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

extension MyVaultsViewModel {
    static var preview: MyVaultsViewModel { .init(vaultSelection: .preview) }
}
