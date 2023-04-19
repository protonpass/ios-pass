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

enum GeneratePasswordViewMode {
    /// View is shown as part of create login process
    case createLogin
    /// View is shown indepently without any context
    case random

    var confirmTitle: String {
        switch self {
        case .createLogin:
            return "Confirm"
        case .random:
            return "Copy and close"
        }
    }
}

enum PasswordUtils {
    static func generateColoredPasswords(_ password: String) -> [Text] {
        var texts = [Text]()
        password.forEach { char in
            var color = Color(uiColor: PassColor.textNorm)
            if AllowedCharacter.digit.rawValue.contains(char) {
                color = Color(uiColor: PassColor.loginInteractionNormMajor2)
            } else if AllowedCharacter.special.rawValue.contains(char) {
                color = Color(uiColor: PassColor.aliasInteractionNormMajor2)
            }
            texts.append(Text(String(char)).foregroundColor(color))
        }
        return texts
    }
}

final class GeneratePasswordViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    let mode: GeneratePasswordViewMode

    @Published private(set) var password = ""
    @Published private(set) var texts: [Text] = []
    @Published var length: Double = 16
    @Published var hasSpecialCharacters = true

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: GeneratePasswordViewModelDelegate?

    init(mode: GeneratePasswordViewMode) {
        self.mode = mode
        self.regenerate()

        $password
            .sink { [unowned self] newPassword in
                texts = PasswordUtils.generateColoredPasswords(newPassword)
            }
            .store(in: &cancellables)

        $length
            .removeDuplicates()
            .sink { [unowned self] newValue in
                regenerate(length: newValue, hasSpecialCharacters: hasSpecialCharacters)
            }
            .store(in: &cancellables)

        $hasSpecialCharacters
            .sink { [unowned self] newValue in
                regenerate(length: length, hasSpecialCharacters: newValue)
            }
            .store(in: &cancellables)
    }

    func regenerate() {
        regenerate(length: length, hasSpecialCharacters: hasSpecialCharacters)
    }

    private func regenerate(length: Double, hasSpecialCharacters: Bool) {
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
