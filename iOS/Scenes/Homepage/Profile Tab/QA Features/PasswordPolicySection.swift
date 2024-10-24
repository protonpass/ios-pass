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
            Section(header: Text(verbatim: "Random Password Settings").font(.headline.bold())) {
                Toggle(isOn: $viewModel.randomPasswordAllowed,
                       label: { Text(verbatim: "Allow Random Password") })

                Picker(selection: $viewModel.randomPasswordMinLength,
                       content: {
                           ForEach(8...20, id: \.self) { length in
                               Text(verbatim: "\(length)").tag(length)
                           }
                       }, label: { Text(verbatim: "Min Length") })

                Picker(selection: $viewModel.randomPasswordMaxLength,
                       content: {
                           ForEach(20...40, id: \.self) { length in
                               Text(verbatim: "\(length)").tag(length)
                           }
                       }, label: { Text(verbatim: "Max Length") })

                Toggle(isOn: $viewModel.randomPasswordMustIncludeNumbers,
                       label: { Text(verbatim: "Must Include Numbers") })
                Toggle(isOn: $viewModel.randomPasswordMustIncludeSymbols,
                       label: { Text(verbatim: "Must Include Symbols") })
                Toggle(isOn: $viewModel.randomPasswordMustIncludeUppercase,
                       label: { Text(verbatim: "Must Include Uppercase") })
            }

            Section(header: Text(verbatim: "Memorable Password Settings").font(.headline.bold())) {
                Toggle(isOn: $viewModel.memorablePasswordAllowed,
                       label: { Text(verbatim: "Allow Memorable Password") })

                Picker(selection: $viewModel.memorablePasswordMinWords,
                       content: {
                           ForEach(1...5, id: \.self) { wordCount in
                               Text(verbatim: "\(wordCount)").tag(wordCount)
                           }
                       }, label: { Text(verbatim: "Min Words") })

                Picker(selection: $viewModel.memorablePasswordMaxWords,
                       content: { ForEach(5...15, id: \.self) { wordCount in
                           Text(verbatim: "\(wordCount)").tag(wordCount)
                       }}, label: { Text(verbatim: "Max Words") })

                Toggle(isOn: $viewModel.memorablePasswordMustCapitalize,
                       label: { Text(verbatim: "Capitalize Words") })
                Toggle(isOn: $viewModel.memorablePasswordMustIncludeNumbers,
                       label: { Text(verbatim: "Must Include Numbers") })
            }
        }
        .padding(DesignConstant.sectionPadding)
        .navigationTitle(Text(verbatim: "Password Policy Settings"))
    }
}

@MainActor
private final class PasswordPolicyViewModel: ObservableObject {
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
                                        memorablePasswordMustIncludeNumbers: memorablePasswordMustIncludeNumbers)
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
