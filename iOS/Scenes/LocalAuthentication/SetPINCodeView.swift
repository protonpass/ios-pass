//
// SetPINCodeView.swift
// Proton Pass - Created on 13/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Factory
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SetPINCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var state: PINState = .definition
    @State private var definedPIN = ""
    @State private var confirmedPIN = ""
    @State private var error: ValidationError?
    private let preferences = resolve(\SharedToolingContainer.preferences)
    var onSet: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 12) {
                Text(state.title)
                    .font(.largeTitle.bold())
                    .foregroundColor(PassColor.textNorm.toColor)

                Text(state.description)
                    .font(.callout)
                    .foregroundColor(PassColor.textWeak.toColor)

                SecureField(state.placeholder, text: state == .definition ? $definedPIN : $confirmedPIN)
                    .keyboardType(.numberPad)
                    .font(.title)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .padding(.top, 50)
                    .focused($isFocused)

                if let error {
                    Text(error.description)
                        .foregroundColor(PassColor.signalDanger.toColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .background(PassColor.backgroundNorm.toColor)
            .animation(.default, value: error)
            .toolbar { toolbarContent }
            .onAppear { isFocused = true }
            .onChange(of: definedPIN) { _ in
                error = nil
            }
            .onChange(of: confirmedPIN) { _ in
                error = nil
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(PassColor.interactionNormMajor1.toColor)
        .tint(PassColor.interactionNormMajor1.toColor)
        .theme(preferences.theme)
    }
}

private extension SetPINCodeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: state.actionTitle,
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: actionButtonDisabled,
                                        action: action)
        }
    }

    var actionButtonDisabled: Bool {
        // Always disabled when error occurs
        guard error == nil else { return true }
        let minLength = Constants.PINCode.minLength
        let maxLength = Constants.PINCode.maxLength
        switch state {
        case .definition:
            return definedPIN.isEmpty || !(minLength...maxLength).contains(definedPIN.count)
        case .confirmation:
            return confirmedPIN.isEmpty || !(minLength...maxLength).contains(confirmedPIN.count)
        }
    }

    func action() {
        switch state {
        case .definition:
            if definedPIN.isValid(allowedCharacters: .decimalDigits) {
                state = .confirmation
            } else {
                error = .invalidCharacters
            }
        case .confirmation:
            if confirmedPIN.isValid(allowedCharacters: .decimalDigits) {
                if confirmedPIN == definedPIN {
                    onSet(definedPIN)
                } else {
                    error = .notMatched
                }
            } else {
                error = .invalidCharacters
            }
        }
    }
}

private extension SetPINCodeView {
    // Can not use the name `State` because it clashes with `@State`
    enum PINState {
        case definition, confirmation

        var title: String {
            switch self {
            case .definition:
                return "Set PIN code"
            case .confirmation:
                return "Repeat PIN code"
            }
        }

        var description: String {
            switch self {
            case .definition:
                return "Unlock the app with this code"
            case .confirmation:
                return "Type your PIN again to confirm"
            }
        }

        var placeholder: String {
            switch self {
            case .definition:
                return "Choose a PIN code"
            case .confirmation:
                return "Repeat PIN code"
            }
        }

        var actionTitle: String {
            switch self {
            case .definition:
                return "Continue"
            case .confirmation:
                return "Set PIN code"
            }
        }
    }

    enum ValidationError: Error {
        case invalidCharacters, notMatched

        var description: String {
            switch self {
            case .invalidCharacters:
                return "PIN must contain only numeric characters (0-9)"
            case .notMatched:
                return "PINs not matched"
            }
        }
    }
}
