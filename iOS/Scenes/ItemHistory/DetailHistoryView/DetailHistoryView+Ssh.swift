//
// DetailHistoryView+Ssh.swift
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
import Screens
import SwiftUI

extension DetailHistoryView {
    var sshView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedRevisionContent

            titleRow(itemContent: itemContent)

            if let data = itemContent.sshKey {
                keysSection(data)
                    .padding(.top, 8)
            }

            customFields(item: itemContent)
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
    func keysSection(_ data: SshKeyData) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            publicKeyRow(data)
            PassSectionDivider()
            privateKeyRow(data)
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedDetailSection()
    }

    func publicKeyRow(_ data: SshKeyData) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Public key")
                .sectionTitleText()

            if data.publicKey.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(data.publicKey)
                    .lineLimit(3)
                    .foregroundStyle(textColor(for: \.sshKey?.publicKey).toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture { selectedKeyType = .public }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }

    func privateKeyRow(_ data: SshKeyData) -> some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
            Text("Private key")
                .sectionTitleText()

            if data.privateKey.isEmpty {
                Text("Empty")
                    .placeholderText()
            } else {
                Text(String(repeating: "•", count: 12))
                    .foregroundStyle(textColor(for: \.sshKey?.privateKey).toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .onTapGesture { selectedKeyType = .private }
        .padding(.horizontal, DesignConstant.sectionPadding)
    }
}
