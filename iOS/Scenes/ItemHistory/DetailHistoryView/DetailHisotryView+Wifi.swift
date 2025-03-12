//
// DetailHisotryView+Wifi.swift
// Proton Pass - Created on 12/03/2025.
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
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

extension DetailHistoryView {
    var wifiView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            titleRow(itemContent: itemContent)

            if let data = itemContent.wifi {
                ssidAndPasswordSection(data)
                    .padding(.top, 8)
            }

            customFields(item: itemContent, showIcon: false)
                .padding(.top, 8)

            customSections(itemContent.customSections)

            attachmentsSection(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

private extension DetailHistoryView {
    func ssidAndPasswordSection(_ data: WifiData) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            ssidRow(data)
            PassSectionDivider()
            passwordRow(data)
            PassSectionDivider()
            securityRow(data)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    func ssidRow(_ data: WifiData) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Name (SSID)")
                .sectionTitleText()

            if data.ssid.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(data.ssid)
                    .foregroundStyle(textColor(for: \.wifi?.ssid).toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture(perform: viewModel.copyWifiSsid)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func passwordRow(_ data: WifiData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if data.password.isEmpty {
                    Text("Empty")
                        .placeholderText()
                } else if isShowingPassword {
                    Text(data.password)
                        .foregroundStyle(textColor(for: \.wifi?.password).toColor)
                } else {
                    Text(String(repeating: "•", count: 12))
                        .foregroundStyle(textColor(for: \.wifi?.password).toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture(perform: viewModel.copyWifiPassword)

            Spacer()

            CircleButton(icon: isShowingPassword ? IconProvider.eyeSlash : IconProvider.eye,
                         iconColor: viewModel.currentRevision.type.normMajor2Color,
                         backgroundColor: viewModel.currentRevision.type.normMinor2Color,
                         accessibilityLabel: isShowingPassword ? "Hide password" : "Show password",
                         action: { isShowingPassword.toggle() })
                .fixedSize(horizontal: true, vertical: true)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func securityRow(_ data: WifiData) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Security type")
                .sectionTitleText()

            Text(data.security.displayName)
                .foregroundStyle(textColor(for: \.wifi?.security).toColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
