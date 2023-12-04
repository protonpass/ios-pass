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
import DesignSystem
import Entities
import Factory
import SwiftUI

protocol GeneratePasswordViewModelDelegate: AnyObject {
    func generatePasswordViewModelDidConfirm(password: String)
}

protocol GeneratePasswordViewModelUiDelegate: AnyObject {
    func generatePasswordViewModelWantsToUpdateSheetHeight(isShowingAdvancedOptions: Bool)
}

enum PasswordUtils {
    static func generateColoredPassword(_ password: String) -> AttributedString {
        let attributedChars = password.map { char in
            var attributedChar = AttributedString("\(char)")
            attributedChar.foregroundColor = if AllowedCharacter.digit.rawValue.contains(char) {
                PassColor.loginInteractionNormMajor2
            } else if AllowedCharacter.special.rawValue.contains(char) ||
                AllowedCharacter.separator.rawValue.contains(char) {
                PassColor.aliasInteractionNormMajor2
            } else {
                PassColor.textNorm
            }
            return attributedChar
        }
        var attributedString = attributedChars.reduce(into: .init()) { $0 += $1 }
        // Set an empty language id to trick SwiftUI into not adding hyphens for multiline passwords
        attributedString.languageIdentifier = ""
        return attributedString
    }
}

final class GeneratePasswordViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    let mode: GeneratePasswordViewMode

    @Published private(set) var password = ""
    @Published private(set) var strength: PasswordStrength = .vulnerable

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

    var coloredPassword: AttributedString {
        PasswordUtils.generateColoredPassword(password)
    }

    private var cachedWords = [String]()

    private let generatePassword = resolve(\SharedUseCasesContainer.generatePassword)
    private let generateRandomWords = resolve(\SharedUseCasesContainer.generateRandomWords)
    private let generatePassphrase = resolve(\SharedUseCasesContainer.generatePassphrase)
    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    init(mode: GeneratePasswordViewMode) {
        self.mode = mode
        regenerate()
    }
}

// MARK: - Public APIs

extension GeneratePasswordViewModel {
    func regenerate(forceRefresh: Bool = true) {
        do {
            defer {
                strength = getPasswordStrength(password: password) ?? .vulnerable
            }

            switch type {
            case .random:
                password = try generatePassword(length: Int(characterCount),
                                                numbers: hasNumberCharacters,
                                                uppercaseLetters: hasCapitalCharacters,
                                                symbols: hasSpecialCharacters)
            case .memorable:
                if forceRefresh || cachedWords.isEmpty {
                    cachedWords = try generateRandomWords(wordCount: Int(wordCount))
                }
                password = try generatePassphrase(words: cachedWords,
                                                  separator: wordSeparator,
                                                  capitalise: capitalizingWords,
                                                  includeNumbers: includingNumbers)
            }
        } catch {
            router.display(element: .displayErrorBanner(error))
        }
    }

    func changeType(_ type: PasswordType) {
        self.type = type
    }

    func changeWordSeparator(_ separator: WordSeparator) {
        wordSeparator = separator
    }

    func confirm() {
        delegate?.generatePasswordViewModelDidConfirm(password: password)
    }
}

// MARK: - Private APIs

private extension GeneratePasswordViewModel {
    func requestHeightUpdate() {
        uiDelegate?
            .generatePasswordViewModelWantsToUpdateSheetHeight(isShowingAdvancedOptions: isShowingAdvancedOptions)
    }
}
