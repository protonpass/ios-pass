//
// PasswordGeneratorView.swift
// Proton Pass - Created on 25/06/2026.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI
import UseCases

public struct PasswordGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PasswordGeneratorViewModel
    @State private var maxPasswordHeight = 0.0
    private let onHeightChanged: ((Double) -> Void)?

    public init(viewModel: PasswordGeneratorViewModel,
                onHeightChanged: ((Double) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onHeightChanged = onHeightChanged
    }

    public var body: some View {
        VStack {
            mainContent
        }
        .frame(maxHeight: viewModel.mode.fullScreen ? .infinity : nil)
        .task {
            await viewModel.checkForOrganisationLimitation()
        }
        .onChange(of: viewModel.preferences, initial: true) {
            viewModel.persistAndRegenerate()
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.mode)
        .animation(.default, value: viewModel.password)
        .animation(.default, value: viewModel.showAdvancedOptions)
        .if(!viewModel.mode.fullScreen) { view in
            view
                .fittedPresentationDetent(onHeightChanged: onHeightChanged)
        }
    }
}

private extension PasswordGeneratorView {
    @ViewBuilder
    var mainContent: some View {
        topBar
        passwordText
        strenghtAndPenalties
        PassDivider()

        if viewModel.shouldDisplayTypeSelection {
            type
            PassDivider()
        }

        switch viewModel.passwordType {
        case .random:
            randomPasswordOptions

        case .memorable:
            memorablePasswordOptions
        }

        if viewModel.mode.fullScreen {
            Spacer()
        } else {
            ctaButtons
        }
    }

    @ViewBuilder
    var topBar: some View {
        switch viewModel.mode {
        case .createLogin, .random:
            HStack {
                circleRegenerateButton
                    .opacity(0)
                Text("Generate password", bundle: .module)
                    .navigationTitleText()
                    .frame(maxWidth: .infinity, alignment: .center)
                circleRegenerateButton
            }

        case .autofill:
            HStack {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)

                Spacer()

                CapsuleTextButton(title: #localized("Use this password", bundle: .module),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNormMajor1,
                                  maxWidth: nil,
                                  action: viewModel.handleCta)
            }
        }
    }

    var circleRegenerateButton: some View {
        CircleButton(icon: IconProvider.arrowsRotate,
                     iconColor: PassColor.loginInteractionNormMajor2,
                     backgroundColor: PassColor.loginInteractionNormMinor1,
                     accessibilityLabel: "Regenerate password",
                     action: { viewModel.regenerate() })
    }

    var passwordText: some View {
        HStack(alignment: .center) {
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

            Spacer()

            Image(systemName: viewModel.strength.iconName)
                .scaledToFit()
                .frame(width: 16)
                .foregroundStyle(viewModel.strength.color)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding * 3 / 4)
        .background(PassColor.inputBackgroundNorm)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(PassColor.inputBorderNorm, lineWidth: 2)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
    }

    var strenghtAndPenalties: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
            Text("Password", bundle: .module)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm) +
                Text(verbatim: " • ")
                .foregroundStyle(PassColor.textNorm) +
                Text(verbatim: viewModel.strength.title)
                .fontWeight(.bold)
                .foregroundStyle(viewModel.strength.color)

            ForEach(PasswordPenalty.allCases, id: \.self) { penalty in
                let included = viewModel.penalties.contains(penalty)
                Label(title: {
                    Text(penalty.title, bundle: .module)
                        .foregroundStyle(PassColor.textNorm)
                        .font(.callout)
                }, icon: {
                    Image(systemName: included ? "xmark" : "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8)
                        .foregroundStyle(included ? PassColor.signalDanger : PassColor.signalSuccess)
                })
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var type: some View {
        HStack {
            Text("Type", bundle: .module)
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu(content: {
                ForEach(PasswordType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.passwordType = type
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
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    IconProvider.chevronDownFilled
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(PassColor.textHint)
                        .frame(width: 16)
                }
            })
        }
    }
}

// MARK: - Random password options

private extension PasswordGeneratorView {
    @ViewBuilder
    var randomPasswordOptions: some View {
        characterCountRow

        PassDivider()

        toggle(title: "Special characters", isOn: $viewModel.hasSpecialCharacters)
        PassDivider()

        if viewModel.showAdvancedOptions {
            toggle(title: "Capital letters", isOn: $viewModel.hasCapitalCharacters)
            PassDivider()

            toggle(title: "Include numbers", isOn: $viewModel.hasNumberCharacters)
            PassDivider()
        } else {
            advancedOptionsRow
        }
    }

    var characterCountRow: some View {
        HStack {
            Text("\(Int(viewModel.characterCount)) characters", bundle: .module)
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $viewModel.characterCount,
                   in: viewModel.minChar...viewModel.maxChar,
                   step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }
}

// MARK: - Memorable password options

private extension PasswordGeneratorView {
    @ViewBuilder
    var memorablePasswordOptions: some View {
        wordCountRow
        PassDivider()

        capitalizingWordsRow
        PassDivider()

        if viewModel.showAdvancedOptions {
            wordSeparatorRow
            PassDivider()

            toggle(title: "Include numbers", isOn: $viewModel.includingNumbers)
            PassDivider()
        } else {
            advancedOptionsRow
        }
    }

    var wordCountRow: some View {
        HStack {
            Text("\(Int(viewModel.wordCount)) word(s)", bundle: .module)
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $viewModel.wordCount,
                   in: viewModel.minWord...viewModel.maxWord,
                   step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }

    var capitalizingWordsRow: some View {
        toggle(title: "Capitalize", isOn: $viewModel.capitalizingWords)
    }

    var wordSeparatorRow: some View {
        HStack {
            Text("Word separator", bundle: .module)
                .foregroundStyle(PassColor.textNorm)

            Spacer()

            Menu(content: {
                ForEach(WordSeparator.allCases) { separator in
                    Button(action: {
                        viewModel.wordSeparator = separator
                    }, label: {
                        HStack {
                            Text(verbatim: separator.title)
                            Spacer()
                            if viewModel.wordSeparator == separator {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                HStack {
                    Text(verbatim: viewModel.wordSeparator.title)
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
    }
}

// MARK: - Shared building blocks

private extension PasswordGeneratorView {
    var advancedOptionsRow: some View {
        AdvancedOptionsSection(isShowingAdvancedOptions: $viewModel.showAdvancedOptions)
    }

    var ctaButtons: some View {
        HStack {
            CapsuleTextButton(title: #localized("Cancel", bundle: .module),
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: dismiss.callAsFunction)

            CapsuleTextButton(title: viewModel.mode.confirmTitle,
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.loginInteractionNormMajor1,
                              height: 44,
                              action: {
                                  viewModel.handleCta()
                                  dismiss()
                              })
        }
        .padding(.vertical)
    }

    func toggle(title: LocalizedStringKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title, bundle: .module)
                .foregroundStyle(PassColor.textNorm)
        }
        .toggleStyle(SwitchToggleStyle.pass)
    }
}

private extension PasswordGeneratorMode {
    var fullScreen: Bool {
        if case .autofill = self {
            true
        } else {
            false
        }
    }

    var confirmTitle: String {
        switch self {
        case .createLogin: #localized("Confirm", bundle: .module)
        case .random: #localized("Copy and close", bundle: .module)
        case .autofill: #localized("Use this password", bundle: .module)
        }
    }
}

private extension PasswordPenalty {
    var title: LocalizedStringKey {
        switch self {
        case .noLowercase: "Lowercase letters"
        case .noUppercase: "Uppercase letters"
        case .noNumbers: "Number letters"
        case .noSymbols: "Symbol letters"
        case .short: "At least 12 characters"
        case .consecutive: "No repeated characters"
        case .progressive: "No sequential characters"
        case .containsCommonPassword: "No common passwords"
        }
    }
}

public extension PasswordStrength {
    var title: String {
        switch self {
        case .vulnerable: #localized("Vulnerable", bundle: .module)
        case .weak: #localized("Weak", bundle: .module)
        case .strong: #localized("Strong", bundle: .module)
        }
    }

    var iconName: String {
        switch self {
        case .vulnerable: "xmark.shield.fill"
        case .weak: "exclamationmark.shield.fill"
        case .strong: "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .vulnerable: PassColor.signalDanger
        case .weak: PassColor.signalWarning
        case .strong: PassColor.signalSuccess
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
