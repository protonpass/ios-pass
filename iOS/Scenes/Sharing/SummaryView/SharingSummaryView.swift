//
//
// SharingSummaryView.swift
// Proton Pass - Created on 20/07/2023.
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
//

import Core
import Factory
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SharingSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SharingSummaryViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            headerView
            vaultInfo
            emailInfo
            permissionInfo
            Spacer()
        }
        .errorAlert(error: $viewModel.error)
        .overlay {
            if viewModel.sendingInvite {
                ProgressView()
                    .scaleEffect(2)
            } else {
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(kItemDetailSectionPadding)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .toolbar { toolbarContent }
    }
}

private extension SharingSummaryView {
    var headerView: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Summary")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(PassColor.textNorm.toColor)
            Text("""
            You are about to invite \(attributedText(for: viewModel.infos?
                    .email ?? "")) into your \(attributedText(for: viewModel.infos?.vault?.name ?? "")) vault.
            They will gain access to \(attributedText(for: viewModel.infos?.itemsNum?
                    .toString ?? "0")) items and they will be able to \(attributedText(for: viewModel.infos?.role?
                    .summary ?? ""))
            """)
            .font(.body)
            .foregroundColor(PassColor.textWeak.toColor)
        }
    }

    func attributedText(for text: String) -> AttributedString {
        var result = AttributedString(text)
        result.font = .body.bold()
        result.foregroundColor = PassColor.textNorm
        return result
    }
}

private extension SharingSummaryView {
    var vaultInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vault")
                .font(.body)
                .foregroundColor(PassColor.textWeak.toColor)
                .frame(height: 20)
            if let vault = viewModel.infos?.vault {
                VaultRow(thumbnail: {
                             CircleButton(icon: vault.displayPreferences.icon.icon.bigImage,
                                          iconColor: vault.displayPreferences.color.color.color,
                                          backgroundColor: vault.displayPreferences.color.color.color
                                              .withAlphaComponent(0.16))
                         },
                         title: vault.name,
                         itemCount: viewModel.infos?.itemsNum ?? 0,
                         isSelected: false,
                         height: 60)
            }
        }
    }
}

private extension SharingSummaryView {
    var emailInfo: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("User")
                .font(.body)
                .foregroundColor(PassColor.textWeak.toColor)
                .frame(height: 20)
            HStack(spacing: kItemDetailSectionPadding) {
                SquircleThumbnail(data: .initials(viewModel.infos?.email?.initialsRemovingEmojis() ?? ""),
                                  tintColor: ItemType.login.tintColor,
                                  backgroundColor: ItemType.login.backgroundColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.infos?.email ?? "")
                        .foregroundColor(PassColor.textNorm.toColor)
                }
            }
            .frame(height: 60)
        }
    }
}

private extension SharingSummaryView {
    var permissionInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Permission")
                .font(.body)
                .foregroundColor(PassColor.textWeak.toColor)
                .frame(height: 20)
            if let role = viewModel.infos?.role {
                HStack(spacing: 5) {
                    VStack(alignment: .leading) {
                        Text(role.title)
                            .font(.body)
                            .foregroundColor(PassColor.textNorm.toColor)
                        Text(role.description)
                            .font(.body)
                            .foregroundColor(PassColor.textWeak.toColor)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(PassColor.textWeak.toColor,
                            lineWidth: 1))
            }
        }
    }
}

private extension SharingSummaryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: "Share Vault",
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: false,
                                        action: { viewModel.sendInvite() })
        }
    }
}

struct SharingSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SharingSummaryView()
    }
}
