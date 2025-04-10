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
    private var wordCount: Double = 5

    @AppStorage("capitalizingWords", store: kSharedUserDefaults)
    private var capitalizingWords = true

    @AppStorage("includingNumbers", store: kSharedUserDefaults)
    private var includingNumbers = true

    weak var delegate: (any GeneratePasswordViewModelDelegate)?
    weak var uiDelegate: (any GeneratePasswordViewModelUiDelegate)?

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
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.passwordHistoryRepository)
    private var passwordHistoryRepository

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
        typeOfWordSeparator = separator
        wordSeparator = separator
    }

    func confirm() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await passwordHistoryRepository.insertPassword(password)
            } catch {
                logger.error(error)
            }

            delegate?.generatePasswordViewModelDidConfirm(password: password)
        }
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

            if let plan = accessRepository.access.value?.access.plan, plan.planType == .business {
                do {
                    if qaPasswordPolicyOverride,
                       let string = UserDefaults.standard.string(forKey: Constants.QA.passwordPolicy) {
                        passwordPolicy = PasswordPolicy(rawValue: string)
                    } else {
                        let userId = try await userManager.getActiveUserId()
                        let organization = try await organizationRepository.getOrganization(userId: userId)
                        if let newPasswordPolicy = organization?.settings?.passwordPolicy {
                            passwordPolicy = newPasswordPolicy
                        }
                    }
                } catch {
                    logger.error(error)
                }
            }
            setPasswordLimitations()
            subscribeToChanges()
            regenerate()
        }
    }

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
        activateSpecialCharacters = passwordPolicy?.randomPasswordMustIncludeSymbols ?? hasSpecialCharacters
        activateCapitalCharacters = passwordPolicy?.randomPasswordMustIncludeUppercase ?? hasCapitalCharacters
        activateNumberCharacters = passwordPolicy?.randomPasswordMustIncludeNumbers ?? hasNumberCharacters
        typeOfWordSeparator = wordSeparator

        if let memorablePasswordMinWords = passwordPolicy?.memorablePasswordMinWords {
            minWord = Double(memorablePasswordMinWords)
        }

        if let memorablePasswordMaxWords = passwordPolicy?.memorablePasswordMaxWords {
            maxWord = Double(memorablePasswordMaxWords)
        }

        numberOfWords = passwordPolicy == nil ? wordCount : adjustToRange(numberOfWords, range: minWord...maxWord)
        activateCapitalized = passwordPolicy?.memorablePasswordMustCapitalize ?? capitalizingWords
        includeNumbers = passwordPolicy?.memorablePasswordMustIncludeNumbers ?? includingNumbers

        typeOfWordSeparator = !includeNumbers &&
            (wordSeparator == .numbersAndSymbols || wordSeparator == .numbers) ? .commas : wordSeparator
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

        update($numberOfCharacters.eraseToAnyPublisher(), keyPath: \.characterCount)
        update($activateSpecialCharacters.eraseToAnyPublisher(), keyPath: \.hasSpecialCharacters)
        update($activateCapitalCharacters.eraseToAnyPublisher(), keyPath: \.hasCapitalCharacters)
        update($activateNumberCharacters.eraseToAnyPublisher(), keyPath: \.hasNumberCharacters)

        $typeOfWordSeparator
            .receive(on: DispatchQueue.main)
            .sink { [weak self] new in
                guard let self else { return }
                wordSeparator = new
            }
            .store(in: &cancellables)

        update($numberOfWords.eraseToAnyPublisher(), keyPath: \.wordCount)
        update($activateCapitalized.eraseToAnyPublisher(), keyPath: \.capitalizingWords, forceRefresh: false)
        update($includeNumbers.eraseToAnyPublisher(), keyPath: \.includingNumbers, forceRefresh: false)
    }

    func update<Value: Equatable>(_ publisher: AnyPublisher<Value, Never>,
                                  keyPath: WritableKeyPath<GeneratePasswordViewModel, Value>,
                                  forceRefresh: Bool = true) {
        publisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                guard var self else { return }
                if passwordPolicy == nil {
                    self[keyPath: keyPath] = newValue
                }
                regenerate(forceRefresh: forceRefresh)
            }
            .store(in: &cancellables)
    }
}
