//
// CredentialsViewModel.swift
// Proton Pass - Created on 27/09/2022.
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

import CryptoKit
import SwiftUI

final class CredentialsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }

    @Published private(set) var state = State.idle
    @Published private(set) var items = [ItemListUiModel]()

    private let symmetricKey: SymmetricKey

    var onClose: (() -> Void)?
    var onSelect: (() -> Void)?

    init(symmetricKey: SymmetricKey) {
        self.symmetricKey = symmetricKey
        fetchItems()
    }

    func fetchItems() {}
}

// MARK: - Actions
extension CredentialsViewModel {
    func closeAction() {
        onClose?()
    }

    func select(item: ItemListUiModel) {
        onSelect?()
    }
}
