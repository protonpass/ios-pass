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

import Core
import SwiftUI
import UIComponents

protocol GeneratePasswordViewModelDelegate: AnyObject {
    func generatePasswordViewModelDidConfirm(password: String)
}

protocol GeneratePasswordViewModelUiDelegate: AnyObject {
    func generatePasswordViewModelWantsToChangePasswordType(currentType: PasswordType)
    func generatePasswordViewModelWantsToChangeWordSeparator(currentSeparator: WordSeparator)
    func generatePasswordViewModelWantsToUpdateSheetHeight(passwordType: PasswordType,
                                                           isShowingAdvancedOptions: Bool)
}

enum PasswordUtils {
    static func generateColoredPasswords(_ password: String) -> [Text] {
        var texts = [Text]()
        password.forEach { char in
            var color = Color(uiColor: PassColor.textNorm)
            if AllowedCharacter.digit.rawValue.contains(char) {
                color = Color(uiColor: PassColor.loginInteractionNormMajor2)
            } else if AllowedCharacter.special.rawValue.contains(char) ||
                        AllowedCharacter.separator.rawValue.contains(char) {
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
    let wordProvider: WordProviderProtocol

    @Published private(set) var password = ""
    @Published private(set) var type: PasswordType = .random
    @Published var isShowingAdvancedOptions = false { didSet { requestHeightUpdate() } }

    // Random password options
    @Published var characterCount: Double = 16 {
        didSet {
            if characterCount != oldValue { regenerate() }
        }
    }
    @Published var hasSpecialCharacters = true { didSet { regenerate() } }
    @Published var hasCapitalCharacters = true { didSet { regenerate() } }
    @Published var hasNumberCharacters = true { didSet { regenerate() } }

    // Memorable password options
    @Published private(set) var wordSeparator: WordSeparator = .hyphens { didSet { regenerate() } }
    @Published var wordCount: Double = 4 {
        didSet {
            if wordCount != oldValue { regenerate() }
        }
    }
    @Published var capitalizingWords = false { didSet { regenerate() } }
    @Published var includingNumbers = false { didSet { regenerate() } }

    weak var delegate: GeneratePasswordViewModelDelegate?
    weak var uiDelegate: GeneratePasswordViewModelUiDelegate?

    var texts: [Text] { PasswordUtils.generateColoredPasswords(password) }

    init(mode: GeneratePasswordViewMode, wordProvider: WordProviderProtocol) {
        self.mode = mode
        self.wordProvider = wordProvider
        self.regenerate()
    }
}

// MARK: - Public APIs
extension GeneratePasswordViewModel {
    func regenerate() {
        switch type {
        case .random:
            regenerateRandomPassword()
        case .memorable:
            regenerateMemorablePassword()
        }
    }

    func changeType() {
        uiDelegate?.generatePasswordViewModelWantsToChangePasswordType(currentType: type)
    }

    func changeWordSeparator() {
        uiDelegate?.generatePasswordViewModelWantsToChangeWordSeparator(currentSeparator: wordSeparator)
    }

    func confirm() {
        delegate?.generatePasswordViewModelDidConfirm(password: password)
    }
}

// MARK: - Private APIs
private extension GeneratePasswordViewModel {
    func regenerateRandomPassword() {
        var allowedCharacters: [AllowedCharacter] = [.lowercase]
        if hasSpecialCharacters { allowedCharacters.append(.special) }
        if hasCapitalCharacters { allowedCharacters.append(.uppercase) }
        if hasNumberCharacters { allowedCharacters.append(.digit) }
        password = .random(allowedCharacters: allowedCharacters, length: Int(characterCount))
    }

    func regenerateMemorablePassword() {
        var words = PassphraseGenerator.generate(from: wordProvider, wordCount: Int(wordCount))
        if capitalizingWords { words = words.map { $0.capitalized } }
        if includingNumbers {
            if let randomIndex = words.indices.randomElement(),
               let randomNumber = AllowedCharacter.digit.rawValue.randomElement() {
                words[randomIndex] = words[randomIndex] + String(randomNumber)
            }
        }
        password = words.joined(separator: wordSeparator.value)
    }

    func requestHeightUpdate() {
        uiDelegate?.generatePasswordViewModelWantsToUpdateSheetHeight(
            passwordType: type,
            isShowingAdvancedOptions: isShowingAdvancedOptions)
    }
}

// MARK: PasswordTypesViewModelDelegate
extension GeneratePasswordViewModel: PasswordTypesViewModelDelegate {
    func passwordTypesViewModelDidSelect(type: PasswordType) {
        self.type = type
        self.isShowingAdvancedOptions = false
        regenerate()
        requestHeightUpdate()
    }
}

// MARK: - WordSeparatorsViewModelDelegate
extension GeneratePasswordViewModel: WordSeparatorsViewModelDelegate {
    func wordSeparatorsViewModelDidSelect(separator: WordSeparator) {
        self.wordSeparator = separator
    }
}
