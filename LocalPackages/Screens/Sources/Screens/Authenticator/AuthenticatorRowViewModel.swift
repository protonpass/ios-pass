//
// AuthenticatorRowViewModel.swift
// Proton Pass - Created on 19/03/2024.
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

import Combine
import DIComposition
import Entities
import FactoryKit
import Foundation

@Observable
final class AuthenticatorRowViewModel {
    private(set) var state = TOTPState.empty

    private let totpManager = dependency(\ServiceContainer.totpManager)

    @ObservationIgnored
    private var cancellable: AnyCancellable?

    init() {
        cancellable = totpManager.currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                state = newState
            }
    }

    func bind(uri: String) {
        totpManager.bind(uri: uri)
    }
}
