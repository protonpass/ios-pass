//
// TOTPRow.swift
// Proton Pass - Created on 06/12/2023.
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

import Core
import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct TOTPRow: View {
    @ObservedObject private var totpManager: TOTPManager
    let tintColor: UIColor
    let onCopyTotpToken: (String) -> Void

    init(totpManager: TOTPManager,
         tintColor: UIColor,
         onCopyTotpToken: @escaping (String) -> Void) {
        _totpManager = .init(initialValue: totpManager)
        self.tintColor = tintColor
        self.onCopyTotpToken = onCopyTotpToken
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.lock, color: tintColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("2FA token (TOTP)")
                    .sectionTitleText()

                switch totpManager.state {
                case .empty:
                    EmptyView()
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundStyle(PassColor.signalDanger.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if let data = totpManager.totpData {
                    onCopyTotpToken(data.code)
                }
            }

            switch totpManager.state {
            case let .valid(data):
                TOTPCircularTimer(data: data.timerData)
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: totpManager.state)
    }
}
