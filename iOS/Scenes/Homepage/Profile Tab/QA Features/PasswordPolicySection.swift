//
// PasswordPolicySection.swift
// Proton Pass - Created on 23/10/2024.
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

@_spi(QA)
import Client
import Combine
import Core
import DesignSystem
import Entities
import Factory
import SwiftUI

struct PasswordPolicySection: View {
    var body: some View {
        NavigationLink(destination: { PasswordPolicyView() },
                       label: { Text(verbatim: "Password Policy") })
    }
}

private struct PasswordPolicyView: View {
    @StateObject private var viewModel = PasswordPolicyViewModel()

    @AppStorage(Constants.QA.forcePasswordPolicy)
    private var forcePasswordPolicy = false

    var body: some View {
        List {
            Toggle(isOn: $forcePasswordPolicy) {
                Text(verbatim: "Apply password policy to all users")
            }
            Section(header: Text("Random Password Settings").font(.headline.bold())) {
                Toggle("Allow Random Password", isOn: $viewModel.randomPasswordAllowed)

                Picker("Min Length", selection: $viewModel.randomPasswordMinLength) {
                    ForEach(8...20, id: \.self) { length in
                        Text("\(length)").tag(length)
                    }
                }

                Picker("Max Length", selection: $viewModel.randomPasswordMaxLength) {
                    ForEach(20...40, id: \.self) { length in
                        Text("\(length)").tag(length)
                    }
                }

                Toggle("Must Include Numbers", isOn: $viewModel.randomPasswordMustIncludeNumbers)
                Toggle("Must Include Symbols", isOn: $viewModel.randomPasswordMustIncludeSymbols)
                Toggle("Must Include Uppercase", isOn: $viewModel.randomPasswordMustIncludeUppercase)
            }

            Section(header: Text("Memorable Password Settings").font(.headline.bold())) {
                Toggle("Allow Memorable Password", isOn: $viewModel.memorablePasswordAllowed)

                Picker("Min Words", selection: $viewModel.memorablePasswordMinWords) {
                    ForEach(1...5, id: \.self) { wordCount in
                        Text("\(wordCount)").tag(wordCount)
                    }
                }

                Picker("Max Words", selection: $viewModel.memorablePasswordMaxWords) {
                    ForEach(5...15, id: \.self) { wordCount in
                        Text("\(wordCount)").tag(wordCount)
                    }
                }

                Toggle("Capitalize Words", isOn: $viewModel.memorablePasswordMustCapitalize)
                Toggle("Must Include Numbers", isOn: $viewModel.memorablePasswordMustIncludeNumbers)
            }
        }
        .padding(DesignConstant.sectionPadding)
        .navigationTitle("Password Policy Settings")
    }
}

@MainActor
private final class PasswordPolicyViewModel: ObservableObject {
    /// Credentials grouped by username
    @Published var randomPasswordAllowed = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var randomPasswordMinLength = 10 {
        didSet {
            updatePolicy()
        }
    }

    @Published var randomPasswordMaxLength = 30 {
        didSet {
            updatePolicy()
        }
    }

    @Published var randomPasswordMustIncludeNumbers = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var randomPasswordMustIncludeSymbols = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var randomPasswordMustIncludeUppercase = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var memorablePasswordAllowed = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var memorablePasswordMinWords = 2 {
        didSet {
            updatePolicy()
        }
    }

    @Published var memorablePasswordMaxWords = 5 {
        didSet {
            updatePolicy()
        }
    }

    @Published var memorablePasswordMustCapitalize = true {
        didSet {
            updatePolicy()
        }
    }

    @Published var memorablePasswordMustIncludeNumbers = true {
        didSet {
            updatePolicy()
        }
    }

    @AppStorage(Constants.QA.passwordPolicy)
    private var passwordPolicy = PasswordPolicy.default

    private var cancellables = Set<AnyCancellable>()

    private var updatingValues: Bool = true

    init() {
        updateValues()
    }

    private func updateValues() {
        randomPasswordAllowed = passwordPolicy.randomPasswordAllowed
        randomPasswordMinLength = passwordPolicy.randomPasswordMinLength ?? 10
        randomPasswordMaxLength = passwordPolicy.randomPasswordMaxLength ?? 30
        randomPasswordMustIncludeNumbers = passwordPolicy.randomPasswordMustIncludeNumbers ?? true
        randomPasswordMustIncludeSymbols = passwordPolicy.randomPasswordMustIncludeSymbols ?? true
        randomPasswordMustIncludeUppercase = passwordPolicy.randomPasswordMustIncludeUppercase ?? true
        memorablePasswordAllowed = passwordPolicy.memorablePasswordAllowed
        memorablePasswordMinWords = passwordPolicy.memorablePasswordMinWords ?? 2
        memorablePasswordMaxWords = passwordPolicy.memorablePasswordMaxWords ?? 5
        memorablePasswordMustCapitalize = passwordPolicy.memorablePasswordMustCapitalize ?? true
        memorablePasswordMustIncludeNumbers = passwordPolicy.memorablePasswordMustIncludeNumbers ?? true
        updatingValues.toggle()
    }

    func updatePolicy() {
        guard !updatingValues else {
            return
        }
        passwordPolicy = PasswordPolicy(randomPasswordAllowed: randomPasswordAllowed,
                                        randomPasswordMinLength: randomPasswordMinLength,
                                        randomPasswordMaxLength: randomPasswordMaxLength,
                                        randomPasswordMustIncludeNumbers: randomPasswordMustIncludeNumbers,
                                        randomPasswordMustIncludeSymbols: randomPasswordMustIncludeSymbols,
                                        randomPasswordMustIncludeUppercase: randomPasswordMustIncludeUppercase,
                                        memorablePasswordAllowed: memorablePasswordAllowed,
                                        memorablePasswordMinWords: memorablePasswordMinWords,
                                        memorablePasswordMaxWords: memorablePasswordMaxWords,
                                        memorablePasswordMustCapitalize: memorablePasswordMustCapitalize,
                                        memorablePasswordMustIncludeNumbers: memorablePasswordMustIncludeNumbers,
                                        memorablePasswordMustIncludeSeparator: true)
    }
}

extension PasswordPolicy: @retroactive RawRepresentable {
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
