//
// PasskeyDetailView.swift
// Proton Pass - Created on 23/02/2024.
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

import Core
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct PasskeyDetailView: View {
    private let tintColor = ItemContentType.login.normColor
    let passkey: Passkey
    var onTapUsername: ((String) -> Void)?

    var body: some View {
        ZStack {
            PassColor.backgroundWeak
                .ignoresSafeArea()
            content
        }
        .navigationTitle("Passkey")
        .navigationBarTitleDisplayMode(.inline)
        .navigationStackEmbeded()
    }
}

private extension PasskeyDetailView {
    var content: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            usernameRow
            PassSectionDivider()
            domainRow
            PassSectionDivider()
            keyRow
            PassSectionDivider()
            creationTimeRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
        .padding(DesignConstant.sectionPadding)
    }
}

private extension PasskeyDetailView {
    var usernameRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: PassIcon.passkey, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Username")
                    .sectionTitleText()
                Text(passkey.userName)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .contentShape(.rect)
        .onTapGesture {
            if let onTapUsername {
                onTapUsername(passkey.userName)
            }
        }
    }
}

private extension PasskeyDetailView {
    var domainRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.globe, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Domain")
                    .sectionTitleText()
                Text(passkey.domain)
                    .sectionContentText()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}

private extension PasskeyDetailView {
    var keyRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.key, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Key")
                    .sectionTitleText()
                Text(passkey.keyID)
                    .sectionContentText()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}

private extension PasskeyDetailView {
    var creationTimeRow: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.calendarToday, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Created")
                    .sectionTitleText()
                Text(Int64(passkey.createTime).fullDateString.capitalizingFirstLetter())
                    .sectionContentText()
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)
                if Bundle.main.isQaBuild {
                    Text(passkey.description)
                        .foregroundStyle(PassColor.textNorm)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}

private extension Passkey {
    var description: String {
        let data = creationData
        return "\(data.deviceName) - \(data.osName) \(data.osVersion) (\(data.appVersion))"
    }
}
