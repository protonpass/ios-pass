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
    private let onHeightChanged: ((Double) -> Void)?

    public init(mode: PasswordGeneratorMode,
                onResult: @escaping (Result<String, any Error>) -> Void,
                onHeightChanged: ((Double) -> Void)? = nil) {
        _viewModel = .init(wrappedValue: .init(mode: mode, onResult: onResult))
        self.onHeightChanged = onHeightChanged
    }

    public var body: some View {
        VStack {
            PasswordGeneratorTopBar(viewModel: viewModel)

            if viewModel.mode.fullScreen {
                Text("Customize password", bundle: .module)
                    .foregroundStyle(PassColor.textNorm)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PasswordPreview(password: viewModel.password, strength: viewModel.strength)

            StrengthAndPenalties(strength: viewModel.strength,
                                 penalties: viewModel.penalties,
                                 showingPenalties: viewModel.showingPenalties,
                                 onShowPenalties: viewModel.showPenalties)
            PassDivider()

            if viewModel.shouldDisplayTypeSelection {
                PasswordTypeSelector(viewModel: viewModel)
                PassDivider()
            }

            switch viewModel.passwordType {
            case .random:
                RandomPasswordOptions(viewModel: viewModel)

            case .memorable:
                MemorablePasswordOptions(viewModel: viewModel)
            }

            if viewModel.mode.fullScreen {
                Spacer()
                CapsuleTextButton(title: #localized("Regenerate password", bundle: .module),
                                  titleColor: PassColor.loginInteractionNormMajor2,
                                  backgroundColor: PassColor.loginInteractionNormMinor1,
                                  height: 50,
                                  action: { viewModel.regenerate() })
            } else {
                PasswordGeneratorCtaButtons(confirmTitle: viewModel.mode.confirmTitle,
                                            onConfirm: {
                                                viewModel.handleCta()
                                                dismiss()
                                            },
                                            onCancel: dismiss.callAsFunction)
            }
        }
        .frame(maxHeight: viewModel.mode.fullScreen ? .infinity : nil)
        .task {
            await viewModel.checkForOrganisationLimitation()
        }
        .onChange(of: viewModel.preferences) { old, new in
            guard old != new else {
                return
            }
            viewModel.handlePreferenceChange()
        }
        .onDisappear {
            viewModel.flushPendingPreferences()
        }
        .padding([.top, .horizontal])
        .background(PassColor.backgroundNorm)
        .animation(.default, value: viewModel.showingAdvancedOptions)
        .animation(.default, value: viewModel.showingPenalties)
        .if(!viewModel.mode.fullScreen) { view in
            view
                .fittedPresentationDetent(onHeightChanged: onHeightChanged)
        }
    }
}

// MARK: - Top bar

private struct PasswordGeneratorTopBar: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PasswordGeneratorViewModel

    var body: some View {
        switch viewModel.mode {
        case .createLogin, .random:
            HStack {
                regenerateButton
                    .hidden()
                Text("Generate password", bundle: .module)
                    .navigationTitleText()
                    .frame(maxWidth: .infinity, alignment: .center)
                regenerateButton
            }

        case .autofill:
            HStack {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.loginInteractionNormMajor2,
                             backgroundColor: PassColor.loginInteractionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)

                Spacer()

                CapsuleTextButton(title: #localized("Use this password", bundle: .module),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.loginInteractionNormMajor1,
                                  maxWidth: nil,
                                  action: viewModel.handleCta)
            }
        }
    }

    private var regenerateButton: some View {
        CircleButton(icon: IconProvider.arrowsRotate,
                     iconColor: PassColor.loginInteractionNormMajor2,
                     backgroundColor: PassColor.loginInteractionNormMinor1,
                     accessibilityLabel: "Regenerate password",
                     action: { viewModel.regenerate() })
    }
}

// MARK: - Password preview

private struct PasswordPreview: View {
    let password: String
    let strength: PasswordStrength

    var body: some View {
        HStack(alignment: .center) {
            Text(password.coloredPassword())
                .font(.title3.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .animationsDisabled()

            Spacer()

            Image(systemName: strength.iconName)
                .scaledToFit()
                .frame(width: 16)
                .foregroundStyle(strength.color)
                .accessibilityLabel(strength.title)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignConstant.sectionPadding * 3 / 4)
        .background(PassColor.inputBackgroundNorm)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(PassColor.inputBorderNorm, lineWidth: 2)
        }
        .padding(.bottom, DesignConstant.sectionPadding)
    }
}

// MARK: - Strength & penalties

private struct StrengthAndPenalties: View {
    let strength: PasswordStrength
    let penalties: [PasswordPenalty]
    let showingPenalties: Bool
    let onShowPenalties: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
            if showingPenalties {
                title
                PasswordPenaltiesSection(penalties: penalties)
            } else {
                title
                    .underline(color: strength.color)
                    .buttonEmbeded(action: onShowPenalties)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: Text {
        Text("Password", bundle: .module)
            .fontWeight(.bold)
            .foregroundStyle(PassColor.textNorm) +
            Text(verbatim: " • ")
            .foregroundStyle(PassColor.textNorm) +
            Text(verbatim: strength.title)
            .fontWeight(.bold)
            .foregroundStyle(strength.color)
    }
}

public struct PasswordPenaltiesSection: View {
    let penalties: [PasswordPenalty]

    public init(penalties: [PasswordPenalty]) {
        self.penalties = penalties
    }

    public var body: some View {
        ForEach(PasswordPenalty.allCases, id: \.self) { penalty in
            PenaltyRow(penalty: penalty, satisfied: !penalties.contains(penalty))
        }
    }
}

private struct PenaltyRow: View {
    let penalty: PasswordPenalty
    let satisfied: Bool

    var body: some View {
        Label(title: {
            Text(penalty.title, bundle: .module)
                .foregroundStyle(PassColor.textNorm)
                .font(.callout)
        }, icon: {
            Image(systemName: satisfied ? "checkmark" : "xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 8)
                .foregroundStyle(satisfied ? PassColor.signalSuccess : PassColor.signalDanger)
        })
        .accessibilityElement(children: .combine)
        .accessibilityValue(satisfied ? Text("Satisfied", bundle: .module) : Text("Not satisfied",
                                                                                  bundle: .module))
    }
}

// MARK: - Type selector

private struct PasswordTypeSelector: View {
    @Bindable var viewModel: PasswordGeneratorViewModel

    var body: some View {
        LabeledMenuPicker(title: "Type",
                          selection: $viewModel.passwordType,
                          options: PasswordType.allCases) {
            .localized($0.title)
        }
    }
}

// MARK: - Random password options

private struct RandomPasswordOptions: View {
    @Bindable var viewModel: PasswordGeneratorViewModel

    var body: some View {
        GeneratorSliderRow(title: "\(Int(viewModel.characterCount)) characters",
                           value: $viewModel.characterCount,
                           range: viewModel.minChar.toDouble...viewModel.maxChar.toDouble)

        PassDivider()

        GeneratorToggle(title: "Special characters",
                        isOn: $viewModel.hasSpecialCharacters,
                        isLocked: viewModel.lockedOptions.specialCharacters)
        PassDivider()

        if viewModel.showingAdvancedOptions {
            GeneratorToggle(title: "Capital letters",
                            isOn: $viewModel.hasCapitalCharacters,
                            isLocked: viewModel.lockedOptions.capitalCharacters)
            PassDivider()

            GeneratorToggle(title: "Include numbers",
                            isOn: $viewModel.hasNumberCharacters,
                            isLocked: viewModel.lockedOptions.numberCharacters)
            PassDivider()
        } else {
            AdvancedOptionsSection(isShowingAdvancedOptions: $viewModel.showingAdvancedOptions)
        }
    }
}

// MARK: - Memorable password options

private struct MemorablePasswordOptions: View {
    @Bindable var viewModel: PasswordGeneratorViewModel

    var body: some View {
        GeneratorSliderRow(title: "\(Int(viewModel.wordCount)) word(s)",
                           value: $viewModel.wordCount,
                           range: viewModel.minWord.toDouble...viewModel.maxWord.toDouble)
        PassDivider()

        GeneratorToggle(title: "Capitalize",
                        isOn: $viewModel.capitalizingWords,
                        isLocked: viewModel.lockedOptions.capitalizingWords)
        PassDivider()

        if viewModel.showingAdvancedOptions {
            LabeledMenuPicker(title: "Word separator",
                              selection: $viewModel.wordSeparator,
                              options: WordSeparator.allCases) {
                .verbatim($0.title)
            }
            PassDivider()

            GeneratorToggle(title: "Include numbers",
                            isOn: $viewModel.includingNumbers,
                            isLocked: viewModel.lockedOptions.includingNumbers)
            PassDivider()
        } else {
            AdvancedOptionsSection(isShowingAdvancedOptions: $viewModel.showingAdvancedOptions)
        }
    }
}

// MARK: - Shared building blocks

private struct GeneratorSliderRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(title, bundle: .module)
                .monospacedDigit()
                .frame(minWidth: 120, alignment: .leading)
                .foregroundStyle(PassColor.textNorm)
                .animationsDisabled()
            Slider(value: $value, in: range, step: 1)
                .tint(PassColor.loginInteractionNormMajor1)
        }
    }
}

private struct GeneratorToggle: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    /// When `true` the toggle is dictated by the organisation policy and is shown read-only.
    var isLocked = false

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title, bundle: .module)
                .foregroundStyle(PassColor.textNorm)
        }
        .tint(PassColor.loginInteractionNormMajor2)
        .disabled(isLocked)
    }
}

private struct PasswordGeneratorCtaButtons: View {
    let confirmTitle: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            CapsuleTextButton(title: #localized("Cancel", bundle: .module),
                              titleColor: PassColor.textWeak,
                              backgroundColor: PassColor.textDisabled,
                              height: 44,
                              action: onCancel)

            CapsuleTextButton(title: confirmTitle,
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.loginInteractionNormMajor1,
                              height: 44,
                              action: onConfirm)
        }
        .padding(.vertical)
    }
}

// MARK: - Model presentation helpers

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
        case .noNumbers: "Numbers"
        case .noSymbols: "Symbols"
        case .short: "At least 13 characters"
        case .consecutive: "No repeated characters"
        case .progressive: "No sequential characters"
        case .containsCommonPassword: "No common passwords"
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
