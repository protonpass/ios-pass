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
    let onSelect: (CustomItemTemplate) -> Void

    var body: some View {
        Text(verbatim: "AAAAA")
    }
}

private extension CustomItemTemplatesList {
//    func row(for template: CustomItemTemplate) -> some View {
//
//    }
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
            .init(icon: IconProvider.shield, title: "WiFi Network")
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
