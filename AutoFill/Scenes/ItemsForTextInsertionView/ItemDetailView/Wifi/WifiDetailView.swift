//
// WifiDetailView.swift
// Proton Pass - Created on 11/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

struct WifiDetailView: View {
    @StateObject private var viewModel: WifiDetailViewModel
    @State private var showPassword = false

    init(_ viewModel: WifiDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ssidAndPasswordSection
        CustomFieldSections(itemContentType: viewModel.type,
                            fields: viewModel.customFields,
                            isFreeUser: viewModel.isFreeUser,
                            showIcon: false,
                            onSelectHiddenText: viewModel.autofill,
                            onSelectTotpToken: viewModel.autofill,
                            onUpgrade: viewModel.upgrade)
        CustomSectionsSection(sections: viewModel.customSections,
                              contentType: viewModel.type,
                              isFreeUser: viewModel.isFreeUser,
                              showIcon: false,
                              onCopyHiddenText: viewModel.autofill,
                              onCopyTotpToken: viewModel.autofill,
                              onUpgrade: viewModel.upgrade)
    }
}

private extension WifiDetailView {
    var ssidAndPasswordSection: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ssidRow
            PassSectionDivider()
            passwordRow
            PassSectionDivider()
            securityTypeRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    var ssidRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Name (SSID)")
                .sectionTitleText()

            if viewModel.ssid.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(viewModel.ssid)
                    .sectionContentText()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture { viewModel.autofill(viewModel.ssid) }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    var passwordRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if viewModel.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else {
                    if showPassword {
                        Text(viewModel.password)
                            .font(.body.monospaced())
                            .sectionContentText()
                    } else {
                        Text(String(repeating: "•", count: 12))
                            .sectionContentText()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.autofill(viewModel.password) }

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

    var securityTypeRow: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Security type")
                .sectionTitleText()

            Text(verbatim: viewModel.security.displayName)
                .sectionContentText()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
