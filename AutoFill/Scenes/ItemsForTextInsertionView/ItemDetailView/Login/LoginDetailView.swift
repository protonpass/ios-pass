//
// LoginDetailView.swift
// Proton Pass - Created on 09/10/2024.
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

import DesignSystem
import Entities
import FactoryKit
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct LoginDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: LoginDetailViewModel
    @State private var selectedPasskey: Passkey?
    @State private var showPassword = false

    private var tintColor: UIColor {
        viewModel.type.normColor
    }

    init(_ viewModel: LoginDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            passkeysSection
            usernamePassword2FaSection
            if !viewModel.urls.isEmpty {
                urlsSection
            }
            CustomFieldSections(itemContentType: viewModel.type,
                                fields: viewModel.customFields,
                                isFreeUser: viewModel.isFreeUser,
                                onSelectHiddenText: viewModel.autofill,
                                onSelectTotpToken: viewModel.autofill,
                                onUpgrade: viewModel.upgrade)
        }
        .optionalSheet(binding: $selectedPasskey) { passkey in
            PasskeyDetailView(passkey: passkey,
                              onTapUsername: viewModel.autofill)
                .presentationDetents([.height(380)])
                .environment(\.colorScheme, colorScheme)
        }
        .optionalSheet(binding: $viewModel.selectedAlias) { alias in
            ItemDetailView(item: alias,
                           selectedTextStream: viewModel.selectedTextStream)
                .environment(\.colorScheme, colorScheme)
        }
    }
}

private extension LoginDetailView {
    @ViewBuilder
    var passkeysSection: some View {
        if !viewModel.passkeys.isEmpty {
            ForEach(viewModel.passkeys, id: \.keyID) { passkey in
                PasskeyDetailRow(passkey: passkey,
                                 onTapUsername: viewModel.autofill,
                                 onTap: { selectedPasskey = passkey })
            }
        }
    }
}

private extension LoginDetailView {
    var usernamePassword2FaSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            if viewModel.email.isEmpty, viewModel.username.isEmpty {
                emptyEmailOrUsernameRow
                PassSectionDivider()
            } else {
                if !viewModel.email.isEmpty {
                    emailRow
                    PassSectionDivider()
                }
                if !viewModel.username.isEmpty {
                    usernameRow
                    PassSectionDivider()
                }
            }

            passwordRow

            switch viewModel.totpTokenState {
            case .loading:
                EmptyView()

            case .notAllowed:
                PassSectionDivider()
                totpNotAllowedRow

            case .allowed:
                if viewModel.totpUri.isEmpty {
                    EmptyView()
                } else {
                    PassSectionDivider()
                    TOTPRow(uri: viewModel.totpUri,
                            tintColor: tintColor,
                            onCopyTotpToken: viewModel.autofill)
                }
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .animation(.default, value: viewModel.totpTokenState)
    }

    var totpNotAllowedRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA limit reached")
                    .sectionTitleText()
                UpgradeButtonLite(foregroundColor: viewModel.type.normMajor2Color,
                                  action: viewModel.upgrade)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var emptyEmailOrUsernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.envelope, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email or username")
                    .sectionTitleText()

                Text("Empty")
                    .placeholderText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var emailRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.envelope,
                                  color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address")
                    .sectionTitleText()

                if viewModel.email.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.email)
                        .sectionContentText()

                    if viewModel.isAlias {
                        Button { viewModel.viewAlias() } label: {
                            Text("View alias")
                                .font(.callout)
                                .foregroundStyle(viewModel.type.normMajor2Color.toColor)
                                .underline(color: viewModel.type.normMajor2Color.toColor)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.autofill(viewModel.email) }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                if viewModel.username.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    Text(viewModel.username)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.autofill(viewModel.username) }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if let passwordStrength = viewModel.passwordStrength {
                PasswordStrengthIcon(strength: passwordStrength)
            } else {
                ItemDetailSectionIcon(icon: IconProvider.key, color: tintColor)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(viewModel.passwordStrength.sectionTitle(reuseCount: nil))
                    .font(.footnote)
                    .foregroundStyle(viewModel.passwordStrength.sectionTitleColor)

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if showPassword {
                        Text(viewModel.password.coloredPassword())
                            .font(.body.monospaced())
                    } else {
                        Text(String(repeating: "•", count: 12))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                if !viewModel.password.isEmpty {
                    viewModel.autofill(viewModel.password)
                }
            }

            Spacer()

            if !viewModel.password.isEmpty {
                CircleButton(icon: showPassword ? IconProvider.eyeSlash : IconProvider.eye,
                             iconColor: viewModel.type.normMajor2Color,
                             backgroundColor: viewModel.type.normMinor2Color,
                             accessibilityLabel: showPassword ? "Hide password" : "Show password",
                             action: { showPassword.toggle() })
                    .fixedSize(horizontal: true, vertical: true)
                    .animationsDisabled()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}

private extension LoginDetailView {
    var urlsSection: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.urls, id: \.self) { url in
                        Text(url)
                            .foregroundStyle(viewModel.type.normMajor2Color.toColor)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .onTapGesture {
                                viewModel.autofill(url)
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.default, value: viewModel.urls)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection()
    }
}
