//
// CustomItemTemplatesList.swift
// Proton Pass - Created on 26/02/2025.
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
import SwiftUI

private struct CustomItemTemplateUiModel {
    let icon: UIImage
    let title: LocalizedStringKey
}

struct CustomItemTemplatesList: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (CustomItemTemplate) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                row(for: .fromScratch,
                    alignment: .center,
                    primaryColor: PassColor.interactionNormMajor2,
                    secondaryColor: PassColor.interactionNormMinor1)
                    .padding(.top)

                section("Technology",
                        templates: [
                            .apiCredential,
                            .database,
                            .server,
                            .softwareLicense,
                            .sshKey,
                            .wifi
                        ],
                        primaryColor: PassColor.interactionNormMajor2,
                        secondaryColor: PassColor.interactionNormMinor2)

                section("Finance",
                        templates: [.bankAccount, .cryptoWallet],
                        primaryColor: PassColor.noteInteractionNormMajor2,
                        secondaryColor: PassColor.noteInteractionNormMinor2)

                section("Personal",
                        templates: [
                            .driverLicense,
                            .medicalRecord,
                            .membership,
                            .passport,
                            .rewardProgram,
                            .socialSecurityNumber
                        ],
                        primaryColor: PassColor.aliasInteractionNormMajor2,
                        secondaryColor: PassColor.aliasInteractionNormMinor2)
            }
            .padding(.horizontal)
        }
        .fullSheetBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .principal) {
                Text("Custom item")
                    .navigationTitleText()
            }
        }
        .navigationStackEmbeded()
    }
}

private extension CustomItemTemplatesList {
    func section(_ title: LocalizedStringKey,
                 templates: [CustomItemTemplate],
                 primaryColor: Color,
                 secondaryColor: Color) -> some View {
        Section(content: {
            ForEach(templates, id: \.self) { template in
                row(for: template,
                    alignment: .leading,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor)
            }
        }, header: {
            Text(title)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
        })
    }

    func row(for template: CustomItemTemplate,
             alignment: Alignment,
             primaryColor: Color,
             secondaryColor: Color) -> some View {
        HStack {
            Image(uiImage: template.uiModel.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18)
                .foregroundStyle(primaryColor)
            Text(template.uiModel.title)
                .fontWeight(.medium)
                .foregroundStyle(PassColor.textNorm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .frame(height: 56)
        .padding(.horizontal)
        .background(secondaryColor)
        .clipShape(.capsule)
        .buttonEmbeded {
            dismiss()
            onSelect(template)
        }
    }
}

private extension CustomItemTemplate {
    var uiModel: CustomItemTemplateUiModel {
        switch self {
        case .fromScratch:
            .init(icon: IconProvider.pencil, title: "Start from scratch")
        case .apiCredential:
            .init(icon: IconProvider.code, title: "API Credential")
        case .database:
            .init(icon: IconProvider.storage, title: "Database")
        case .server:
            .init(icon: IconProvider.servers, title: "Server")
        case .softwareLicense:
            .init(icon: IconProvider.fileLines, title: "Software License")
        case .sshKey:
            .init(icon: IconProvider.filingCabinet, title: "SSH Key")
        case .wifi:
            .init(icon: UIImage(systemName: "wifi") ?? IconProvider.shield,
                  title: "WiFi Network")
        case .bankAccount:
            .init(icon: PassIcon.bank, title: "Bank Account")
        case .cryptoWallet:
            .init(icon: PassIcon.brandBitcoin, title: "Crypto Wallet")
        case .driverLicense:
            .init(icon: IconProvider.cardIdentity, title: "Driver License")
        case .medicalRecord:
            .init(icon: IconProvider.heart, title: "Medical Record")
        case .membership:
            .init(icon: IconProvider.userCircle, title: "Membership")
        case .passport:
            .init(icon: IconProvider.cardIdentity, title: "Passport")
        case .rewardProgram:
            .init(icon: IconProvider.bagPercent, title: "Reward Program")
        case .socialSecurityNumber:
            .init(icon: IconProvider.users, title: "Social Security Number")
        }
    }
}
