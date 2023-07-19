//
//
// UserEmailViewModel.swift
// Proton Pass - Created on 19/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Combine
import Foundation
import ProtonCore_HumanVerification

@MainActor
final class UserEmailViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published private(set) var canContinue = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }
}

private extension UserEmailViewModel {
    func setUp() {
        $email
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
//                guard !newValue.isEmpty else {
//                    self?.canContinue = false
//                    return
//                }
                self?.canContinue = newValue.isValidEmail()
            }
            .store(in: &cancellables)
    }
}
