//
// UsernameGeneratorView.swift
// Proton Pass - Created on 15/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Client
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI
import UseCases

public struct UsernameGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: UsernameGeneratorViewModel
    @State private var maxUsernameHeight = 0.0
    @State private var showAdvancedOptions = false

    public init(onResult: @escaping (Result<String, any Error>) -> Void) {
        _viewModel = .init(initialValue: .init(onResult: onResult))
    }

    public var body: some View {
        VStack {
            titleBar

            usernameText
                .padding(.bottom)

            wordCountRow

            PassDivider()

            separatorRow

            PassDivider()

            if showAdvancedOptions {
                advancedOptions
                PassDivider()
            } else {
                AdvancedOptionsSection(isShowingAdvancedOptions: $showAdvancedOptions)
            }

            ctaButtons
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .presentationDragIndicator(.visible)
        .animation(.default, value: showAdvancedOptions)
        .fittedPresentationDetent()
        .onChange(of: viewModel.preferences, initial: true) {
            viewModel.persistAndRegenerate()
        }
    }
}

private extension UsernameGeneratorView {
    var titleBar: some View {
        HStack {
            regenerateButton
                .opacity(0)
            Spacer()
            Text("Generate username")
                .navigationTitleText()
            Spacer()
            regenerateButton
        }
    }

    var usernameText: some View {
        Text(viewModel.username.coloredPassword())
            .font(.title3.monospaced())
            .frame(minHeight: max(32, maxUsernameHeight), alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .animationsDisabled()
            .onGeometryChange(for: Double.self,
                              of: { $0.size.height },
                              action: { newHeight in
                                  if newHeight > maxUsernameHeight {
                                      maxUsernameHeight = newHeight
                                  }
                              })
    }

    var regenerateButton: some View {
        CircleButton(icon: IconProvider.arrowsRotate,
                     iconColor: PassColor.loginInteractionNormMajor2,
                     backgroundColor: PassColor.loginInteractionNormMinor1,
                     accessibilityLabel: "Regenerate username",
                     action: { viewModel.regenerate() })
    }

    var wordCountRow: some View {
        HStack {
            Text("\(Int(viewModel.wordCount)) word(s)")
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $viewModel.wordCount,
                   in: Double(UsernamePreferences.minWordCount)...Double(UsernamePreferences.maxWordCount),
                   step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }

    var separatorRow: some View {
        HStack {
            Text("Word separator")
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu(content: {
                ForEach(WordSeparator.allCases) { separator in
                    Button(action: {
                        viewModel.separator = separator
                    }, label: {
                        HStack {
                            Text(verbatim: separator.title)
                            Spacer()
                            if viewModel.separator == separator {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(verbatim: viewModel.separator.title)
                        .foregroundStyle(PassColor.textNorm)
                        .frame(maxWidth: .infinity, alignment: .trailing)
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

    var ctaButtons: some View {
        HStack {
            CapsuleTextButton(title: #localized("Cancel"),
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: dismiss.callAsFunction)

            CapsuleTextButton(title: #localized("Confirm"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.loginInteractionNormMajor1,
                              height: 44,
                              action: {
                                  viewModel.confirm()
                                  dismiss()
                              })
        }
        .padding(.vertical)
    }

    @ViewBuilder
    var advancedOptions: some View {
        toggle(title: "Include numbers", isOn: $viewModel.includeNumbers)
        PassDivider()
        toggle(title: "Capitalize", isOn: $viewModel.capitalize)
        PassDivider()
        toggle(title: "Leetspeak", isOn: $viewModel.leetspeak)
        PassDivider()
        toggle(title: "Include adjectives",
               isOn: $viewModel.includeAdjectives,
               disabled: !viewModel.includeNouns && !viewModel.includeVerbs)
        PassDivider()
        toggle(title: "Include nouns",
               isOn: $viewModel.includeNouns,
               disabled: !viewModel.includeAdjectives && !viewModel.includeVerbs)
        PassDivider()
        toggle(title: "Include verbs",
               isOn: $viewModel.includeVerbs,
               disabled: !viewModel.includeAdjectives && !viewModel.includeNouns)
    }

    func toggle(title: LocalizedStringKey,
                isOn: Binding<Bool>,
                disabled: Bool = false) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .foregroundStyle(PassColor.textNorm)
        }
        .toggleStyle(SwitchToggleStyle.pass)
        .disabled(disabled)
    }
}
