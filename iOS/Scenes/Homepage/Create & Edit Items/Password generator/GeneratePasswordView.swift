//
// GeneratePasswordView.swift
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

import DesignSystem
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct GeneratePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GeneratePasswordViewModel
    @State private var maxPasswordHeight = 0.0
    private let onConfirm: (String) -> Void
    private let onUpdateHeight: ((Double) -> Void)?

    init(mode: GeneratePasswordViewMode,
         onConfirm: @escaping (String) -> Void,
         onUpdateHeight: ((Double) -> Void)? = nil) {
        _viewModel = .init(wrappedValue: .init(mode: mode))
        self.onConfirm = onConfirm
        self.onUpdateHeight = onUpdateHeight
    }

    var body: some View {
        VStack {
            HStack {
                // Hidden gimmick button to make the navigation title centered properly
                regeneratePasswordButton
                    .opacity(0)

                Spacer()

                Text("Generate password")
                    .navigationTitleText()

                Spacer()

                regeneratePasswordButton
            }

            // The height of password text grows as text gets longer
            // We remember the last known max height and make it the min height
            // in order to avoid animation glitch when height increases and decreases as lenght changes
            Text(viewModel.password.coloredPassword())
                .font(.title3.monospaced())
                .frame(minHeight: max(32, maxPasswordHeight), alignment: .center)
                .fixedSize(horizontal: false, vertical: true)
                .animationsDisabled()
                .onGeometryChange(for: Double.self,
                                  of: { $0.size.height },
                                  action: { newHeight in
                                      if newHeight > maxPasswordHeight {
                                          maxPasswordHeight = newHeight
                                      }
                                  })

            Label(viewModel.strength.title, systemImage: viewModel.strength.iconName)
                .font(.headline)
                .foregroundStyle(viewModel.strength.color)
                .animationsDisabled()

            if viewModel.shouldDisplayTypeSelection {
                passwordTypeRow
                PassDivider()
            }

            switch viewModel.passwordType {
            case .random:
                if viewModel.minChar < viewModel.maxChar {
                    characterCountRow
                }
                PassDivider()

                toggle(title: "Special characters",
                       isOn: $viewModel.activateSpecialCharacters,
                       hasPolicy: viewModel.passwordPolicy?.randomPasswordMustIncludeSymbols != nil)
                PassDivider()

                if viewModel.isShowingAdvancedOptions {
                    toggle(title: "Capital letters",
                           isOn: $viewModel.activateCapitalCharacters,
                           hasPolicy: viewModel.passwordPolicy?.randomPasswordMustIncludeUppercase != nil)
                    PassDivider()

                    toggle(title: "Include numbers",
                           isOn: $viewModel.activateNumberCharacters,
                           hasPolicy: viewModel.passwordPolicy?.randomPasswordMustIncludeNumbers != nil)
                    PassDivider()
                } else {
                    advancedOptionsRow
                }

            case .memorable:
                if viewModel.minWord < viewModel.maxWord {
                    wordCountRow
                }
                PassDivider()
                if viewModel.isShowingAdvancedOptions {
                    wordSeparatorRow
                    PassDivider()

                    capitalizingWordsRow
                    PassDivider()

                    toggle(title: "Include numbers",
                           isOn: $viewModel.includeNumbers,
                           hasPolicy: viewModel.passwordPolicy?.memorablePasswordMustIncludeNumbers != nil)
                    PassDivider()
                } else {
                    capitalizingWordsRow
                    PassDivider()

                    advancedOptionsRow
                }
            }

            ctaButtons
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.password)
        .animation(.default, value: viewModel.isShowingAdvancedOptions)
        .presentationDragIndicator(.visible)
        .fittedPresentationDetent { onUpdateHeight?($0) }
    }
}

private extension GeneratePasswordView {
    var regeneratePasswordButton: some View {
        CircleButton(icon: IconProvider.arrowsRotate,
                     iconColor: PassColor.loginInteractionNormMajor2,
                     backgroundColor: PassColor.loginInteractionNormMinor1,
                     accessibilityLabel: "Regenerate password",
                     action: { viewModel.regenerate() })
    }

    var passwordTypeRow: some View {
        HStack {
            Text("Type")
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu(content: {
                ForEach(PasswordType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.changeType(type)
                    }, label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if viewModel.passwordType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(viewModel.passwordType.title)
                        .foregroundStyle(PassColor.textNorm)
                    IconProvider.chevronDownFilled
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint)
                        .frame(width: 16)
                }
            })
        }
        .animationsDisabled()
    }

    var advancedOptionsRow: some View {
        AdvancedOptionsSection(isShowingAdvancedOptions: $viewModel.isShowingAdvancedOptions)
    }

    var ctaButtons: some View {
        HStack {
            CapsuleTextButton(title: #localized("Cancel"),
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: dismiss.callAsFunction)

            CapsuleTextButton(title: viewModel.mode.confirmTitle,
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.loginInteractionNormMajor1,
                              height: 44,
                              action: {
                                  viewModel.saveHistory { password in
                                      onConfirm(password)
                                      dismiss()
                                  }
                              })
        }
        .padding(.vertical)
    }

    var characterCountRow: some View {
        HStack {
            Text("\(Int(viewModel.numberOfCharacters)) characters")
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $viewModel.numberOfCharacters, in: viewModel.minChar...viewModel.maxChar, step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }

    var wordCountRow: some View {
        HStack {
            Text("\(Int(viewModel.numberOfWords)) word(s)")
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $viewModel.numberOfWords, in: viewModel.minWord...viewModel.maxWord, step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }

    func toggle(title: LocalizedStringKey, isOn: Binding<Bool>, hasPolicy: Bool = false) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .foregroundStyle(PassColor.textNorm)
        }
        .toggleStyle(SwitchToggleStyle.pass)
        .disabled(hasPolicy)
    }

    var capitalizingWordsRow: some View {
        toggle(title: "Capitalize",
               isOn: $viewModel.activateCapitalized,
               hasPolicy: viewModel.passwordPolicy?.memorablePasswordMustCapitalize != nil)
    }

    var wordSeparatorRow: some View {
        HStack {
            Text("Word separator")
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu(content: {
                ForEach(WordSeparator.allCases, id: \.self) { separator in
                    Button(action: {
                        viewModel.changeWordSeparator(separator)
                    }, label: {
                        HStack {
                            Text(separator.title)
                            Spacer()
                            if viewModel.typeOfWordSeparator == separator {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(viewModel.typeOfWordSeparator.title)
                        .foregroundStyle(PassColor.textNorm)
                    IconProvider.chevronDownFilled
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint)
                        .frame(width: 16)
                }
            })
        }
        .animationsDisabled()
    }
}

private extension GeneratePasswordViewMode {
    var confirmTitle: String {
        switch self {
        case .createLogin: #localized("Confirm")
        case .random: #localized("Copy and close")
        }
    }
}

private extension PasswordType {
    var title: LocalizedStringKey {
        switch self {
        case .random: "Random password"
        case .memorable: "Memorable password"
        }
    }
}

private extension WordSeparator {
    var title: LocalizedStringKey {
        switch self {
        case .hyphens: "Hyphens"
        case .spaces: "Spaces"
        case .periods: "Periods"
        case .commas: "Commas"
        case .underscores: "Underscores"
        case .numbers: "Numbers"
        case .numbersAndSymbols: "Numbers and Symbols"
        }
    }
}
