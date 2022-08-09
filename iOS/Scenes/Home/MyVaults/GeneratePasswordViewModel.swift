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
import UIComponents

protocol GeneratePasswordViewModelDelegate: AnyObject {
    func generatePasswordViewModelDidConfirm(password: String)
}

final class GeneratePasswordViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var password = ""
    @Published private(set) var texts: [Text] = []
    @Published var length: Double = 32
    @Published var hasSpecialCharacters = true

    private var cancellables = Set<AnyCancellable>()
    let lengthRange: ClosedRange<Double> = 10...128

    weak var delegate: GeneratePasswordViewModelDelegate?

    init() {
        self.regenerate()

        $password
            .sink { [unowned self] newPassword in
                texts.removeAll()
                newPassword.forEach { char in
                    var color = Color.primary
                    if AllowedCharacter.uppercase.rawValue.contains(char) {
                        color = PassColor.letters
                    } else if AllowedCharacter.lowercase.rawValue.contains(char) {
                        color = PassColor.letters
                    } else if AllowedCharacter.digit.rawValue.contains(char) {
                        color = PassColor.digits
                    } else if AllowedCharacter.special.rawValue.contains(char) {
                        color = PassColor.specialCharacters
                    }
                    texts.append(Text(String(char)).foregroundColor(color))
                }
            }
            .store(in: &cancellables)

        $length
            .removeDuplicates()
            .sink { [unowned self] _ in
                self.regenerate()
            }
            .store(in: &cancellables)

        // Throttle to wait for Toggle's animation
        // if not the value of the boolean will be incorrect
        $hasSpecialCharacters
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [unowned self] _ in
                self.regenerate()
            }
            .store(in: &cancellables)
    }

    func regenerate() {
        var allowedCharacters: [AllowedCharacter] = [.lowercase, .uppercase, .digit]
        if hasSpecialCharacters {
            allowedCharacters.append(.special)
        }
        password = .random(allowedCharacters: allowedCharacters, length: Int(length))
    }

    func confirm() {
        delegate?.generatePasswordViewModelDidConfirm(password: password)
    }
}
