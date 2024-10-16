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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct GeneratePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GeneratePasswordViewModel

    init(viewModel: GeneratePasswordViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text(viewModel.coloredPassword)
                    .font(.title3.monospaced())
                    .minimumScaleFactor(0.5)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .animationsDisabled()

                Label(viewModel.strength.title, systemImage: viewModel.strength.iconName)
                    .font(.headline)
                    .foregroundStyle(viewModel.strength.color)

                passwordTypeRow
                PassDivider()

                switch viewModel.type {
                case .random:
                    characterCountRow
                    PassDivider()

                    toggle(title: #localized("Special characters"),
                           isOn: $viewModel.hasSpecialCharacters)
                    PassDivider()

                    if viewModel.isShowingAdvancedOptions {
                        toggle(title: #localized("Capital letters"),
                               isOn: $viewModel.hasCapitalCharacters)
                        PassDivider()

                        toggle(title: #localized("Include numbers"),
                               isOn: $viewModel.hasNumberCharacters)
                        PassDivider()
                    } else {
                        advancedOptionsRow
                    }

                case .memorable:
                    wordCountRow
                    PassDivider()
                    if viewModel.isShowingAdvancedOptions {
                        wordSeparatorRow
                        PassDivider()

                        capitalizingWordsRow
                        PassDivider()

                        toggle(title: #localized("Include numbers"),
                               isOn: $viewModel.includingNumbers)
                        PassDivider()
                    } else {
                        capitalizingWordsRow
                        PassDivider()

                        advancedOptionsRow
                    }
                }

                ctaButtons
            }
            .padding(.horizontal)
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: viewModel.password)
            .animation(.default, value: viewModel.isShowingAdvancedOptions)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Hidden gimmick button to make the navigation title centered properly
                    CircleButton(icon: IconProvider.arrowsRotate,
                                 iconColor: PassColor.interactionNormMajor1,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: { viewModel.regenerate() })
                        .opacity(0)
                }

                ToolbarItem(placement: .principal) {
                    Text("Generate password")
                        .navigationTitleText()
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CircleButton(icon: IconProvider.arrowsRotate,
                                 iconColor: PassColor.loginInteractionNormMajor2,
                                 backgroundColor: PassColor.loginInteractionNormMinor1,
                                 accessibilityLabel: "Regenerate password",
                                 action: { viewModel.regenerate() })
                }
            }
        }
    }

    private var passwordTypeRow: some View {
        HStack {
            Text("Type")
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()

            Menu(content: {
                ForEach(PasswordType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.changeType(type)
                    }, label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if viewModel.type == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(viewModel.type.title)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Image(uiImage: IconProvider.chevronDownFilled)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint.toColor)
                        .frame(width: 16)
                }
            })
        }
        .animationsDisabled()
    }

    private var advancedOptionsRow: some View {
        AdvancedOptionsSection(isShowingAdvancedOptions: $viewModel.isShowingAdvancedOptions)
    }

    private var ctaButtons: some View {
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
                                  viewModel.confirm()
                                  if case .createLogin = viewModel.mode {
                                      dismiss()
                                  }
                              })
        }
        .padding(.vertical)
    }

    private var characterCountRow: some View {
        HStack {
            Text("\(Int(viewModel.characterCount)) characters")
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm.toColor)
                .animationsDisabled()
            Slider(value: $viewModel.characterCount, in: 4...64, step: 1)
                .tint(PassColor.loginInteractionNormMajor1.toColor)
        }
    }

    private var wordCountRow: some View {
        HStack {
            Text("\(Int(viewModel.wordCount)) word(s)")
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm.toColor)
                .animationsDisabled()
            Slider(value: $viewModel.wordCount, in: 1...10, step: 1)
                .tint(PassColor.loginInteractionNormMajor1.toColor)
        }
    }

    private func toggle(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .foregroundStyle(PassColor.textNorm.toColor)
        }
        .toggleStyle(SwitchToggleStyle.pass)
    }

    private var capitalizingWordsRow: some View {
        toggle(title: #localized("Capitalize"), isOn: $viewModel.capitalizingWords)
    }

    private var wordSeparatorRow: some View {
        HStack {
            Text("Word separator")
                .foregroundStyle(PassColor.textNorm.toColor)

            Spacer()

            Menu(content: {
                ForEach(WordSeparator.allCases, id: \.self) { separator in
                    Button(action: {
                        viewModel.changeWordSeparator(separator)
                    }, label: {
                        HStack {
                            Text(separator.title)
                            Spacer()
                            if viewModel.wordSeparator == separator {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(viewModel.wordSeparator.title)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Image(uiImage: IconProvider.chevronDownFilled)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint.toColor)
                        .frame(width: 16)
                }
            })
        }
        .animationsDisabled()
    }
}
