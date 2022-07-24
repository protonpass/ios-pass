//
// GeneratePasswordViewModel.swift
// Proton Pass - Created on 24/07/2022.
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

import Combine
import Core
import SwiftUI

final class GeneratePasswordViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    private let coordinator: MyVaultsCoordinator
    private var allowedCharacters: [AllowedCharacter] {
        var allowedCharacters: [AllowedCharacter] = [.lowercase, .uppercase, .digit]
        if hasSpecialCharacters {
            allowedCharacters.append(.special)
        }
        return allowedCharacters
    }

    @Published private(set) var password = ""
    @Published var length: Double = 32
    @Published var hasSpecialCharacters = true {
        didSet {
            self.regenerate()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    let lengthRange: ClosedRange<Double> = 10...128

    init(coordinator: MyVaultsCoordinator) {
        self.coordinator = coordinator
        self.regenerate()

        $length
            .removeDuplicates()
            .sink { [unowned self] _ in
                self.regenerate()
            }
            .store(in: &cancellables)
    }

    func cancelAction() {
        coordinator.dismissTopMostModal()
    }

    func regenerate() {
        password = .random(allowedCharacters: allowedCharacters, length: Int(length))
    }
}

extension GeneratePasswordViewModel {
    static var preview: GeneratePasswordViewModel { .init(coordinator: .preview) }
}
