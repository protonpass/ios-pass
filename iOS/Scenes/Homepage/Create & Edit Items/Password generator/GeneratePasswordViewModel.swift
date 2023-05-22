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

    @AppStorage("passwordType", store: kSharedUserDefaults)
    private(set) var type: PasswordType = .memorable {
        didSet {
            regenerate(forceRefresh: false)
            requestHeightUpdate()
        }
    }

    @Published var isShowingAdvancedOptions = false { didSet { requestHeightUpdate() } }

    // Random password options
    @AppStorage("characterCount", store: kSharedUserDefaults)
    var characterCount: Double = 16 { didSet { if characterCount != oldValue { regenerate() } } }

    @AppStorage("hasSpecialCharacters", store: kSharedUserDefaults)
    var hasSpecialCharacters = true { didSet { regenerate() } }

    @AppStorage("hasCapitalCharacters", store: kSharedUserDefaults)
    var hasCapitalCharacters = true { didSet { regenerate() } }

    @AppStorage("hasNumberCharacters", store: kSharedUserDefaults)
    var hasNumberCharacters = true { didSet { regenerate() } }

    // Memorable password options
    @AppStorage("wordSeparator", store: kSharedUserDefaults)
    private(set) var wordSeparator: WordSeparator = .hyphens {
        didSet {
            regenerate(forceRefresh: false)
            requestHeightUpdate()
        }
    }

    @AppStorage("wordCount", store: kSharedUserDefaults)
    var wordCount: Double = 4 { didSet { if wordCount != oldValue { regenerate() } } }

    @AppStorage("capitalizingWords", store: kSharedUserDefaults)
    var capitalizingWords = true { didSet { regenerate(forceRefresh: false) } }

    @AppStorage("includingNumbers", store: kSharedUserDefaults)
    var includingNumbers = true { didSet { regenerate(forceRefresh: false) } }

    weak var delegate: GeneratePasswordViewModelDelegate?
    weak var uiDelegate: GeneratePasswordViewModelUiDelegate?

    var texts: [Text] { PasswordUtils.generateColoredPasswords(password) }

    private var cachedWords = [String]()

    init(mode: GeneratePasswordViewMode, wordProvider: WordProviderProtocol) {
        self.mode = mode
        self.wordProvider = wordProvider
        self.regenerate()
    }
}

// MARK: - Public APIs
extension GeneratePasswordViewModel {
    func regenerate(forceRefresh: Bool = true) {
        switch type {
        case .random:
            regenerateRandomPassword()
        case .memorable:
            regenerateMemorablePassword(forceRefresh: forceRefresh)
        }
    }

    func changeType(_ type: PasswordType) {
        self.type = type
    }

    func changeWordSeparator(_ separator: WordSeparator) {
        self.wordSeparator = separator
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

    func regenerateMemorablePassword(forceRefresh: Bool) {
        if forceRefresh || cachedWords.isEmpty {
            cachedWords = PassphraseGenerator.generate(from: wordProvider, wordCount: Int(wordCount))
        }

        var words = cachedWords

        if capitalizingWords { words = words.map { $0.capitalized } }

        if includingNumbers {
            if let randomIndex = words.indices.randomElement(),
               let randomNumber = AllowedCharacter.digit.rawValue.randomElement() {
                words[randomIndex] = words[randomIndex] + String(randomNumber)
            }
        }

        var password = ""
        for (index, word) in words.enumerated() {
            password += word
            if index != words.count - 1 {
                password += wordSeparator.value
            }
        }

        self.password = password
    }

    func requestHeightUpdate() {
        uiDelegate?.generatePasswordViewModelWantsToUpdateSheetHeight(
            passwordType: type,
            isShowingAdvancedOptions: isShowingAdvancedOptions)
    }
}
