//
// CreateEditCustomItemViewModel.swift
// Proton Pass - Created on 27/02/2025.
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

import Client
import Core
import Entities
import Foundation
import Macro
import SwiftUICore

private struct DefaultField {
    let title: String
    let type: `Type`

    enum `Type` {
        case text, hiddenText, date
    }

    var customFieldType: CustomFieldType {
        switch type {
        case .text: .text
        case .hiddenText: .hidden
        case .date: .timestamp
        }
    }

    init(title: String, type: Type = .text) {
        self.title = title
        self.type = type
    }
}

final class CreateEditCustomItemViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    override func bindValues() {
        switch mode {
        case let .create(_, type):
            if case let .custom(template) = type {
                assert(template != .sshKey && template != .wifi,
                       "SSH key and Wifi are not supported as custom item")
                customFields = template.defaultFields.map {
                    .init(title: $0.title, type: $0.customFieldType, content: "")
                }
            }

        case let .clone(itemContent), let .edit(itemContent):
            if case let .custom(data) = itemContent.contentData {
                title = itemContent.name
            }
        }
    }

    override var itemContentType: ItemContentType { .custom }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: "",
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.custom(.init(sections: [])),
                            customFields: [])
    }
}

private extension DefaultField {
    static var expiryDate: Self {
        .init(title: #localized("Expiry date"), type: .date)
    }

    static var dateOfBirth: Self {
        .init(title: #localized("Date of Birth"), type: .date)
    }

    static var username: Self {
        .init(title: #localized("Username"))
    }

    static var password: Self {
        .init(title: #localized("Password"), type: .hiddenText)
    }

    static var note: Self {
        .init(title: #localized("Note"))
    }
}

private extension CustomItemTemplate {
    var defaultFields: [DefaultField] {
        switch self {
        case .fromScratch:
            []

        case .apiCredential:
            [
                .init(title: #localized("API key"), type: .hiddenText),
                .init(title: #localized("Secret"), type: .hiddenText),
                .expiryDate,
                .init(title: #localized("Permissions")),
                .note
            ]

        case .database:
            [
                .init(title: #localized("Host")),
                .init(title: #localized("Port")),
                .username,
                .password,
                .init(title: #localized("Database type")),
                .note
            ]

        case .server:
            [
                .init(title: #localized("IP address")),
                .init(title: #localized("Hostname")),
                .init(title: #localized("OS")),
                .username,
                .password,
                .note
            ]

        case .softwareLicense:
            [
                .init(title: #localized("License key"), type: .hiddenText),
                .init(title: #localized("Product")),
                .expiryDate,
                .init(title: #localized("Owner")),
                .note
            ]

        case .sshKey, .wifi:
            // Not applicable
            []

        case .bankAccount:
            [
                .init(title: #localized("Bank name")),
                .init(title: #localized("Account number")),
                .init(title: #localized("Routing number")),
                .init(title: #localized("Account type")),
                .init(title: #localized("IBAN"), type: .hiddenText),
                .init(title: #localized("SWIFT/BIC")),
                .init(title: #localized("Holder name")),
                .note
            ]

        case .cryptoWallet:
            [
                .init(title: #localized("Wallet name")),
                .init(title: #localized("Address")),
                .init(title: #localized("Private key"), type: .hiddenText),
                .init(title: #localized("Seed phrase"), type: .hiddenText),
                .init(title: #localized("Network")),
                .note
            ]

        case .driverLicense:
            [
                .init(title: #localized("Full name")),
                .init(title: #localized("License number")),
                .init(title: #localized("Issuing State/Country")),
                .expiryDate,
                .dateOfBirth,
                .init(title: #localized("Class")),
                .note
            ]

        case .medicalRecord:
            [
                .init(title: #localized("Patient name")),
                .init(title: #localized("Record number"), type: .hiddenText),
                .init(title: #localized("Medical conditions"), type: .hiddenText),
                .init(title: #localized("Medications"), type: .hiddenText),
                .init(title: #localized("Doctor")),
                .init(title: #localized("Hospital")),
                .note
            ]

        case .membership:
            [
                .init(title: #localized("Organization name")),
                .init(title: #localized("Membership ID")),
                .init(title: #localized("Member name")),
                .expiryDate,
                .init(title: #localized("Tier/Level")),
                .note
            ]

        case .passport:
            [
                .init(title: #localized("Full name")),
                .init(title: #localized("Passport number")),
                .init(title: #localized("Country")),
                .expiryDate,
                .dateOfBirth,
                .init(title: #localized("Issuing authority"), type: .date),
                .note
            ]

        case .rewardProgram:
            [
                .init(title: #localized("Program name")),
                .init(title: #localized("Member ID")),
                .init(title: #localized("Points balance")),
                .expiryDate,
                .init(title: #localized("Tier/Status")),
                .note
            ]

        case .socialSecurityNumber:
            [
                .init(title: #localized("Full name")),
                .init(title: #localized("Social security number"), type: .hiddenText),
                .init(title: #localized("Issuing country")),
                .note
            ]
        }
    }
}
