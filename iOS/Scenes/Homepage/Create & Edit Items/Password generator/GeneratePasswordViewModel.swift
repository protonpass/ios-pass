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
import DesignSystem
import Entities
import Factory
import SwiftUI

@MainActor
protocol GeneratePasswordViewModelDelegate: AnyObject {
    func generatePasswordViewModelDidConfirm(password: String)
}

@MainActor
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
        // Trick SwiftUI into not adding hyphens for multiline passwords
        attributedString.languageIdentifier = "vi"
        return attributedString
    }
}

@MainActor
final class GeneratePasswordViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    let mode: GeneratePasswordViewMode

    @Published var passwordType: PasswordType = .memorable
    @Published var numberOfCharacters: Double = 20
    @Published var activateSpecialCharacters: Bool = true
    @Published var activateCapitalCharacters: Bool = true
    @Published var activateNumberCharacters: Bool = true
    @Published var typeOfWordSeparator: WordSeparator = .hyphens
    @Published var numberOfWords: Double = 5
    @Published var activateCapitalized: Bool = true
    @Published var includeNumbers: Bool = true
    @Published private(set) var password = ""
    @Published private(set) var strength: PasswordStrength = .vulnerable
    @Published private(set) var loading = false
    @Published private(set) var minChar: Double = 4
    @Published private(set) var maxChar: Double = 64
    @Published private(set) var minWord: Double = 1
    @Published private(set) var maxWord: Double = 10
    @Published private(set) var passwordPolicy: PasswordPolicy?

    @Published var isShowingAdvancedOptions = false { didSet { requestHeightUpdate() } }

    private var qaPasswordPolicyOverride: Bool {
        UserDefaults.standard.bool(forKey: Constants.QA.forcePasswordPolicy)
    }

    @AppStorage("passwordType", store: kSharedUserDefaults)
    private var type: PasswordType = .memorable {
        didSet {
            regenerate(forceRefresh: false)
            requestHeightUpdate()
        }
    }

    // Random password options
    @AppStorage("characterCount", store: kSharedUserDefaults)
    private var characterCount: Double = 20

    @AppStorage("hasSpecialCharacters", store: kSharedUserDefaults)
    private var hasSpecialCharacters = true

    @AppStorage("hasCapitalCharacters", store: kSharedUserDefaults)
    private var hasCapitalCharacters = true

    @AppStorage("hasNumberCharacters", store: kSharedUserDefaults)
    private var hasNumberCharacters = true

    // Memorable password options
    @AppStorage("wordSeparator", store: kSharedUserDefaults)
    private var wordSeparator: WordSeparator = .hyphens {
        didSet {
            regenerate(forceRefresh: false)
            requestHeightUpdate()
        }
    }

    @AppStorage("wordCount", store: kSharedUserDefaults)
    private var wordCount: Double = 5 { didSet { if wordCount != oldValue { regenerate() } } }

    @AppStorage("capitalizingWords", store: kSharedUserDefaults)
    private var capitalizingWords = true { didSet { regenerate(forceRefresh: false) } }

    @AppStorage("includingNumbers", store: kSharedUserDefaults)
    private var includingNumbers = true { didSet { regenerate(forceRefresh: false) } }

    weak var delegate: (any GeneratePasswordViewModelDelegate)?
    weak var uiDelegate: (any GeneratePasswordViewModelUiDelegate)?

    var coloredPassword: AttributedString {
        PasswordUtils.generateColoredPassword(password)
    }

    var shouldDisplayTypeSelection: Bool {
        if let randomPasswordAllowed = passwordPolicy?.randomPasswordAllowed, !randomPasswordAllowed {
            return false
        }

        if let memorablePasswordAllowed = passwordPolicy?.memorablePasswordAllowed, !memorablePasswordAllowed {
            return false
        }

        return true
    }

    private var cachedWords = [String]()
    private let generatePassword = resolve(\SharedUseCasesContainer.generatePassword)
    private let generateRandomWords = resolve(\SharedUseCasesContainer.generateRandomWords)
    private let generatePassphrase = resolve(\SharedUseCasesContainer.generatePassphrase)
    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    @LazyInjected(\SharedRepositoryContainer.organizationRepository) private var organizationRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    private var cancellables = Set<AnyCancellable>()

    init(mode: GeneratePasswordViewMode) {
        self.mode = mode

        checkForOrganisationLimitation()
    }
}

// MARK: - Public APIs

extension GeneratePasswordViewModel {
    func regenerate(forceRefresh: Bool = true) {
        do {
            defer {
                strength = getPasswordStrength(password: password) ?? .vulnerable
            }

            switch passwordType {
            case .random:
                password = try generatePassword(length: Int(numberOfCharacters),
                                                numbers: activateNumberCharacters,
                                                uppercaseLetters: activateCapitalCharacters,
                                                symbols: activateSpecialCharacters)
            case .memorable:
                if forceRefresh || cachedWords.isEmpty {
                    cachedWords = try generateRandomWords(wordCount: Int(numberOfWords))
                }
                password = try generatePassphrase(words: cachedWords,
                                                  separator: wordSeparator,
                                                  capitalise: activateCapitalized,
                                                  includeNumbers: includeNumbers)
            }
        } catch {
            router.display(element: .displayErrorBanner(error))
        }
    }

    func changeType(_ type: PasswordType) {
        passwordType = type
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

    func checkForOrganisationLimitation() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            loading = true
            if qaPasswordPolicyOverride {
                if let string = UserDefaults.standard.string(forKey: Constants.QA.passwordPolicy) {
                    passwordPolicy = PasswordPolicy(rawValue: string)
                }
            } else if let userId = try? await userManager.getActiveUserId(),
                      let organization = try? await organizationRepository.refreshOrganization(userId: userId),
                      let newPasswordPolicy = organization.settings?.passwordPolicy {
                passwordPolicy = newPasswordPolicy
            }

            setPasswordLimitations()
            subscribeToChanges()
            regenerate()
        }
    }

    // swiftlint:disable cyclomatic_complexity
    func setPasswordLimitations() {
        passwordType = type

        if let randomPasswordAllowed = passwordPolicy?.randomPasswordAllowed, !randomPasswordAllowed {
            passwordType = .memorable
        }

        if let memorablePasswordAllowed = passwordPolicy?.memorablePasswordAllowed, !memorablePasswordAllowed,
           passwordType == .memorable {
            passwordType = .random
        }

        if let randomPasswordMinLength = passwordPolicy?.randomPasswordMinLength {
            minChar = Double(randomPasswordMinLength)
        }

        if let randomPasswordMaxLength = passwordPolicy?.randomPasswordMaxLength {
            maxChar = Double(randomPasswordMaxLength)
        }
        numberOfCharacters = passwordPolicy == nil ? characterCount : adjustToRange(numberOfCharacters,
                                                                                    range: minChar...maxChar)

        activateSpecialCharacters = if let randomPasswordMustIncludeSymbols = passwordPolicy?
            .randomPasswordMustIncludeSymbols {
            randomPasswordMustIncludeSymbols
        } else {
            hasSpecialCharacters
        }

        activateCapitalCharacters = if let randomPasswordMustIncludeUppercase = passwordPolicy?
            .randomPasswordMustIncludeUppercase {
            randomPasswordMustIncludeUppercase
        } else {
            hasCapitalCharacters
        }

        activateNumberCharacters = if let randomPasswordMustIncludeNumbers = passwordPolicy?
            .randomPasswordMustIncludeNumbers {
            randomPasswordMustIncludeNumbers
        } else {
            hasNumberCharacters
        }

        typeOfWordSeparator = wordSeparator

        if let memorablePasswordMinWords = passwordPolicy?.memorablePasswordMinWords {
            minWord = Double(memorablePasswordMinWords)
        }

        if let memorablePasswordMaxWords = passwordPolicy?.memorablePasswordMaxWords {
            maxWord = Double(memorablePasswordMaxWords)
        }

        numberOfWords = passwordPolicy == nil ? wordCount : adjustToRange(numberOfWords, range: minWord...maxWord)

        activateCapitalized = if let memorablePasswordMustCapitalize = passwordPolicy?
            .memorablePasswordMustCapitalize {
            memorablePasswordMustCapitalize
        } else {
            capitalizingWords
        }

        includeNumbers = if let memorablePasswordIncludeNumbers = passwordPolicy?
            .memorablePasswordMustIncludeNumbers {
            memorablePasswordIncludeNumbers
        } else {
            includingNumbers
        }
    }

    func adjustToRange(_ number: Double, range: ClosedRange<Double>) -> Double {
        if range.contains(number) {
            number
        } else if number < range.lowerBound {
            range.lowerBound
        } else {
            range.upperBound
        }
    }

    func subscribeToChanges() {
        $passwordType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newType in
                guard let self else { return }
                type = newType
            }
            .store(in: &cancellables)

        $numberOfCharacters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    characterCount = new
                }
                regenerate()
            }
            .store(in: &cancellables)

        $activateSpecialCharacters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    hasSpecialCharacters = new
                }
                regenerate()
            }
            .store(in: &cancellables)

        $activateCapitalCharacters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    hasCapitalCharacters = new
                }
                regenerate()
            }
            .store(in: &cancellables)

        $activateNumberCharacters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    hasNumberCharacters = new
                }
                regenerate()
            }
            .store(in: &cancellables)

        $typeOfWordSeparator
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                wordSeparator = new
            }
            .store(in: &cancellables)

        $numberOfWords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    wordCount = new
                }
                regenerate()
            }
            .store(in: &cancellables)

        $activateCapitalized
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    capitalizingWords = new
                }
                regenerate(forceRefresh: false)
            }
            .store(in: &cancellables)

        $includeNumbers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                if passwordPolicy == nil {
                    includingNumbers = new
                }
                regenerate(forceRefresh: false)
            }
            .store(in: &cancellables)
    }
    // swiftlint:enable cyclomatic_complexity
}
