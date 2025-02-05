//
// ImporterView.swift
// Proton Pass - Created on 05/02/2025.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct ImporterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var excludedIds: Set<String> = .init()

    private let logins: [CsvLogin]
    private let onImport: ([CsvLogin]) -> Void

    public init(logins: [CsvLogin],
                onImport: @escaping ([CsvLogin]) -> Void) {
        self.logins = logins
        self.onImport = onImport
    }

    public var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(logins) { login in
                    LoginRow(login: login,
                             isSelected: !excludedIds.contains(where: { $0 == login.id })) {
                        if excludedIds.contains(where: { $0 == login.id }) {
                            excludedIds.remove(login.id)
                        } else {
                            excludedIds.insert(login.id)
                        }
                    }
                    .padding([.horizontal, .top])
                }
            }
        }
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .fullSheetBackground()
        .navigationStackEmbeded()
    }
}

private extension ImporterView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .principal) {
            Text(#localized("Import logins (%1$lld/%2$lld)",
                            logins.count - excludedIds.count,
                            logins.count))
                .navigationTitleText()
                .monospacedDigit()
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Import"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.loginInteractionNormMajor1,
                                        disableBackgroundColor: PassColor.loginInteractionNormMinor1,
                                        disabled: excludedIds.count == logins.count) {
                let loginsToImport = logins.filter { !excludedIds.contains($0.id) }
                onImport(loginsToImport)
            }
        }
    }
}

private struct LoginRow: View {
    let login: CsvLogin
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            SquircleThumbnail(data: .initials(login.initials),
                              tintColor: PassColor.loginInteractionNormMajor2,
                              backgroundColor: PassColor.loginInteractionNormMinor1,
                              height: 40)

            VStack(alignment: .leading) {
                Text(login.name)
                    .lineLimit(2)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(login.emailOrUsername)
                    .lineLimit(2)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 16)
                    .foregroundStyle(PassColor.loginInteractionNormMajor2.toColor)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.default, value: isSelected)
        .buttonEmbeded(action: onTap)
    }
}

private extension CsvLogin {
    var emailOrUsername: String {
        email.isEmpty ? username : email
    }

    var initials: String {
        let nameInitials = name.initials()
        return nameInitials.isEmpty ? emailOrUsername.initials() : nameInitials
    }
}
