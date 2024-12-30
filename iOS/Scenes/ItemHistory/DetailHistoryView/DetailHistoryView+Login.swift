//
// DetailHistoryView+Login.swift
// Proton Pass - Created on 16/01/2024.
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
import Factory
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

extension DetailHistoryView {
    var loginView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            titleRow(itemContent: itemContent)

            if let item = itemContent.loginItem {
                passkeySection(logItem: item)
                usernamePassword2FaSection(logItem: item)
                urlsSection(logItem: item)
                    .padding(.top, 8)
            }

            noteFields(item: itemContent)
                .padding(.top, 8)

            customFields(item: itemContent)
                .padding(.top, 8)

            attachmentsSection(item: itemContent)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

private extension DetailHistoryView {
    @ViewBuilder
    func passkeySection(logItem: LogInItemData) -> some View {
        if logItem.passkeys.isEmpty {
            EmptyView()
        } else {
            ForEach(logItem.passkeys, id: \.keyID) { passkey in
                PasskeyDetailRow(passkey: passkey,
                                 borderColor: borderColor(for: \.loginItem?.passkeys),
                                 onTap: { viewModel.viewPasskey(passkey) })
                    .padding(.bottom, 8)
            }
        }
    }

    func usernamePassword2FaSection(logItem: LogInItemData) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            emailRow(logItem: logItem)
            PassSectionDivider()
            usernameRow(logItem: logItem)
            PassSectionDivider()
            passwordRow(logItem: logItem)
            if !logItem.totpUri.isEmpty {
                PassSectionDivider()
                TOTPRow(uri: logItem.totpUri,
                        textColor: textColor(for: \.loginItem?.totpUri),
                        tintColor: PassColor.loginInteractionNorm,
                        onCopyTotpToken: { viewModel.copyTotpToken($0) })
            }
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    func emailRow(logItem: LogInItemData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user,
                                  color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Email address")
                    .sectionTitleText()

                Text(logItem.email)
                    .foregroundStyle(textColor(for: \.loginItem?.email).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyEmail() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func usernameRow(logItem: LogInItemData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.user,
                                  color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()

                Text(logItem.username)
                    .foregroundStyle(textColor(for: \.loginItem?.username).toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyItemUsername() }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func passwordRow(logItem: LogInItemData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.key, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Password")
                    .sectionTitleText()

                if isShowingPassword {
                    Text(logItem.password)
                        .foregroundStyle(textColor(for: \.loginItem?.password).toColor)
                } else {
                    Text(String(repeating: "•", count: 12))
                        .foregroundStyle(textColor(for: \.loginItem?.password).toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { viewModel.copyPassword() }

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

    func urlsSection(logItem: LogInItemData) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.earth, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Website")
                    .sectionTitleText()

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(logItem.urls, id: \.self) { url in
                        Text(url)
                            .foregroundStyle(viewModel.currentRevision.type.normMajor2Color.toColor)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(borderColor: borderColor(for: \.loginItem?.urls))
    }

    func customFields(item: ItemContent) -> some View {
        VStack {
            let uiModels = item.customFields.map(\.toCustomFieldUiModel)

            ForEach(uiModels) { uiModel in
                let customField = uiModel.customField
                let title = customField.title
                let content = customField.content

                HStack(spacing: DesignConstant.sectionPadding) {
                    ItemDetailSectionIcon(icon: CustomFieldType.text.icon,
                                          color: viewModel.currentRevision.type.normColor)

                    VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                        Text(title)
                            .sectionTitleText()

                        Text(content)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(DesignConstant.sectionPadding)
                .roundedDetailSection()
                .padding(8)
            }
        }
        .roundedDetailSection(borderColor: borderColor(for: \.customFields))
    }
}
